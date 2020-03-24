/* uCaspian Axon
 * Parker Mitchell, 2020
 *
 * This module implements the 'axon' component. The axon is
 * responsible for both handling the mapping of neurons to 
 * synapses and providing axonal delay.
 */
`ifndef uCaspian_Axon_SV
`define uCaspian_Axon_SV

`include "dp_ram.sv"
`include "find_set_bit.sv"

module ucaspian_axon(
    input               clk,
    input               reset,
    input               enable,

    input               clear_act,
    input               clear_config,
    output logic        clear_done,

    // configuration
    input         [7:0] config_addr,
    input        [11:0] config_value,
    input         [2:0] config_byte,
    input               config_enable,

    // time sync
    input               next_step,
    output logic        step_done,

    // neuron -> axon
    input         [7:0] axon_addr,
    input               axon_vld,
    output logic        axon_rdy,

    // axon -> synapse
    output logic [11:0] syn_start,
    output logic [11:0] syn_end,
    output logic        syn_vld,
    input               syn_rdy
);

// Configuration RAM
//   [23:20] Delay cycles
//   [19:8]  First Synapse 
//   [7:0]   Number of synapses
logic  [7:0] config_rd_addr;
logic [23:0] config_rd_data;
logic        config_rd_en;
logic  [7:0] config_wr_addr;
logic [23:0] config_wr_data;
logic        config_wr_en;

dp_ram_24x256 config_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(config_rd_addr),
    .rd_data(config_rd_data),
    .rd_en(config_rd_en),

    .wr_addr(config_wr_addr),
    .wr_data(config_wr_data),
    .wr_en(config_wr_en)
);

// Delay RAM
//   Bitfield representing fires queue
logic [15:0] delay_rd_data;
logic  [7:0] delay_rd_addr;
logic        delay_rd_en;
logic [15:0] delay_wr_data;
logic  [7:0] delay_wr_addr;
logic        delay_wr_en;

dp_ram_16x256 delay_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(delay_rd_addr),
    .rd_data(delay_rd_data),
    .rd_en(delay_rd_en),

    .wr_addr(delay_wr_addr),
    .wr_data(delay_wr_data),
    .wr_en(delay_wr_en)
);

logic [7:0] config_clear_addr;
logic       config_clear_done;

always_ff @(posedge clk) begin
    clear_done <= (clear_config && config_clear_done) || (clear_act); 
end

// Configuration & Clearing
//   This block owns the WRITE port for CONFIG
always_ff @(posedge clk) begin
    config_wr_en      <= 0;
    config_clear_addr <= 0;

    if(clear_config) begin
        // clear addres counter (0 -> 255 & stop)
        if(config_clear_addr < 255) begin
            config_clear_addr <= config_clear_addr + 1;
        end
        else begin 
            config_clear_addr <= config_clear_addr;
            config_clear_done <= 1;
        end

        config_wr_addr <= config_clear_addr;
        config_wr_data <= 0;
        config_wr_en   <= 1;
    end
    else if(config_enable) begin
        config_wr_addr <= config_addr;
        
        case(config_byte)
            1: config_wr_data        <= 0;
            2: config_wr_data[23:20] <= config_value[7:4];
            3: config_wr_data[19:16] <= config_value[3:0];
            4: config_wr_data[15:8]  <= config_value[7:0];
            5: begin
                config_wr_data[7:0]  <= config_value[7:0];
                config_wr_en         <= 1;
            end
        endcase
    end
end

logic arb_block;
logic syn_block;

always_comb axon_rdy = ~arb_block && ~syn_block;
always_comb syn_block = ~syn_rdy && fire_out;
always_comb arb_block = 0; // TODO: change this once needed

always_ff @(posedge clk) begin
    step_done <= ~syn_block && ~arb_block && ~incoming_rd && ~config_rd_en && ~fire_out;
end

logic [7:0] incoming_addr;
logic       incoming_rd;

// Stage 1a: Accept fires from neuron
always_ff @(posedge clk) begin
    if(reset) begin
        incoming_addr <= 0;
        incoming_rd   <= 0;
    end
    else if(axon_vld && axon_rdy) begin
        incoming_addr <= axon_addr;
        incoming_rd   <= 1;
    end
    else begin
        incoming_rd <= 0;
    end
end

// Stage 1b: Scan current activity
//   This block owns the READ port for ACTIVITY
always_ff @(posedge clk) begin
    // TODO
end

// Stage 2: Arbitrate incoming & current activity
//   This block owns the READ port for CONFIG
//   Prioritze incoming fires to keep the pipeline flowing
always_ff @(posedge clk) begin
    // TODO
    // Currently a pass-thru for inconing fires
    if(reset) begin
        config_rd_addr <= 0;
        config_rd_en   <= 0;
    end
    else if(incoming_rd) begin
        config_rd_addr <= incoming_addr;
        config_rd_en   <= incoming_rd;
    end
    else begin
        config_rd_en   <= 0;
    end
end

// Stage 3: Update activity, Pull out config info // 
//   This block owns the WRITE port for ACTIVITY
logic [23:0] config_reg;
logic        fire_out;
always_ff @(posedge clk) begin
    // TODO
    if(reset) fire_out <= 0;
    else if(syn_block) fire_out <= 1;
    else fire_out <= config_rd_en;
end

// Stage 4: Output to synapse
always_ff @(posedge clk) begin
    if(syn_vld && syn_rdy) begin
        syn_vld <= 0;
    end

    if(fire_out && config_rd_data[7:0] != 0) begin
        syn_start <= config_rd_data[19:8];
        syn_end   <= config_rd_data[19:8] + (config_rd_data[7:0] - 1);
        syn_vld   <= 1;
    end
end

endmodule
`endif
