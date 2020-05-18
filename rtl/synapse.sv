/* uCaspian Synapse
 * Parker Mitchell, 2019
 *
 * Each synapse unit corresponds with 1024 synapses. Each synapse
 * has an 8 bit weight as well as target neuron. When a synapse
 * fires, it must look up the weight and target to pass those
 * values to the dendritic accumulator.
 */
`ifndef uCaspian_Synapse_SV
`define uCaspian_Synapse_SV

`include "dp_ram.sv"

module ucaspian_synapse(
    input               clk,
    input               reset,
    input               enable,

    input               clear_act,
    input               clear_config,
    output logic        clear_done,

    // time sync
    output logic        step_done,

    // Configuration/write port
    input         [9:0] cfg_addr,
    input         [7:0] cfg_value,
    input         [2:0] cfg_byte,
    input               cfg_enable,

    // fire from axon to synapse
    input         [9:0] syn_addr,
    input               syn_vld,
    output logic        syn_rdy,

    // fire from synapse to dendrite
    output logic  [7:0] dend_addr,
    output logic  [7:0] dend_charge,
    output logic        dend_vld,
    input               dend_rdy
);



// Configuration RAM
//   [15:8] synaptic weight - 8bits, signed
//    [7:0] target neuron address 
logic  [9:0] config_rd_addr;
logic [15:0] config_rd_data;
logic        config_rd_en;
logic  [9:0] config_wr_addr;
logic [15:0] config_wr_data;
logic        config_wr_en;

dp_ram_16x1024 config_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(config_rd_addr),
    .rd_data(config_rd_data),
    .rd_en(config_rd_en),

    .wr_addr(config_wr_addr),
    .wr_data(config_wr_data),
    .wr_en(config_wr_en)
);

// configuration
logic [9:0] clear_addr;
logic       clear_cfg_done;
always_ff @(posedge clk) begin
    config_wr_en <= 0;

    if(clear_config) begin
        if(clear_addr == 1023) clear_cfg_done <= 1;

        if(~clear_cfg_done) begin
            clear_addr <= clear_addr + 1;
            config_wr_addr <= clear_addr;
            config_wr_data <= 0;
            config_wr_en   <= 1;
        end
    end
    else if(cfg_enable) begin
        config_wr_addr <= cfg_addr;
        case(cfg_byte)
            2: config_wr_data[15:8] <= cfg_value;
            3: begin 
                config_wr_data[7:0] <= cfg_value;
                config_wr_en        <= 1;
            end
        endcase
    end
    else begin
        clear_cfg_done <= 0;
        clear_addr     <= 0;
    end
end

always_ff @(posedge clk) begin
    if(clear_act) clear_done <= 1;
    else if(clear_config) clear_done <= clear_cfg_done;
    else clear_done <= 0;
end

// Synapse Pipeline
logic [9:0]  addr_dly;
logic [15:0] data_dly;
logic        rd_dly;

always_ff @(posedge clk) begin
    //// Step 1: Get incoming synapse
    if(syn_rdy && syn_vld) begin
        config_rd_addr <= syn_addr;
        config_rd_en   <= 1;
    end
    else begin
        config_rd_en   <= 0;
    end

    //// Step 2: Wait for data
    addr_dly <= config_rd_addr;        
    rd_dly   <= config_rd_en;

    //// Step 3: Ouptut data
    if(dend_rdy && dend_vld) begin
        dend_vld <= 0;
    end

    if(rd_dly) begin
        if(!(dend_vld && ~dend_rdy)) begin
            dend_charge <= config_rd_data[15:8];
            dend_addr   <= config_rd_data[7:0];
            dend_vld    <= 1;
        end
        else begin
            rd_dly <= 1; // todo
        end
    end

    if(reset || clear_act || clear_config) begin
        dend_addr   <= 0;
        dend_charge <= 0;
        dend_vld    <= 0;
        addr_dly    <= 0;
        rd_dly      <= 0;
    end
end

always_comb begin
    syn_rdy = ~dend_vld && ~rd_dly && ~config_rd_en;
end

/*
always_comb begin
    if(dend_rdy) syn_rdy = 1;
    else if(~dend_vld && ~rd_dly && ~config_rd_en) syn_rdy = 1;
    else syn_rdy = 0;
end
*/

always_ff @(posedge clk) begin
    step_done <= ~dend_vld && ~syn_vld && ~config_rd_en && ~rd_dly;
end

endmodule
`endif
