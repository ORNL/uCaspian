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
        
        case(config_wr_byte)
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
assign axon_rdy = ~arb_block && ~syn_block;

logic [7:0] incoming_addr;

// Stage 1a: Accept fires from neuron
always_ff @(posedge clk) begin
    if(reset) begin

    end
    else if(axon_vld && axon_rdy) begin
        incoming_addr <= axon_addr;
    end
end

// Stage 1b: Scan current activity
//   This block owns the READ port for ACTIVITY
always_ff @(posedge clk) begin

end

// Stage 2: Arbitrate incoming & current activity
//   This block owns the READ port for CONFIG
//   Prioritze incoming fires to keep the pipeline flowing
always_ff @(posedge clk) begin

end

// Stage 3: Update activity
//   This block owns the WRITE port for ACTIVITY
always_ff @(posedge clk) begin

end

// Stage 4: Output to synapse
always_ff @(posedge clk) begin

end

endmodule
