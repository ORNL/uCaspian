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

// states
localparam [1:0]
    SYN_IDLE                = 0,
    SYN_ACTIVE              = 1,
    SYN_BLOCK_ON_DENDRITE   = 2,
    SYN_DISABLE             = 3;

logic [1:0] synapse_state;
initial synapse_state = SYN_IDLE;

// 16x1k central configuration RAM
//   On Lattice ice40, this will be four 4kbit BRAMs
logic [15:0] synapse_cfg [1023:0];

// configuration
logic [7:0] cfg_weight;
logic [9:0] clear_addr;
logic clear_cfg_done;
always_ff @(posedge clk) begin
    if(clear_config) begin
        if(!clear_cfg_done) begin
            clear_addr <= clear_addr + 1;
            synapse_cfg[clear_addr] <= 0;

            if(clear_addr == 1023) begin
                clear_cfg_done <= 1;
            end
        end
    end
    else begin
        clear_cfg_done  <= 0;
        clear_addr      <= 0;

        if(cfg_enable) begin
            case(cfg_byte)
                // weight
                2: cfg_weight <= cfg_value;
                // target neuron
                3: synapse_cfg[cfg_addr] <= {cfg_weight, cfg_value};
            endcase
        end
    end
end

always_ff @(posedge clk) begin
    if(clear_act)
        clear_done <= 1;
    else if(clear_config)
        clear_done <= clear_cfg_done;
    else
        clear_done <= 0;
end

logic [9:0] syn_addr_reg;

logic [15:0] scfg_temp;
logic [7:0]  dend_addr_temp;
logic [7:0]  dend_ch_temp;
always_comb begin
    scfg_temp      = synapse_cfg[syn_addr_reg];
    dend_ch_temp   = scfg_temp[15:8];
    dend_addr_temp = scfg_temp[7:0];
end

always_comb begin
    syn_rdy = dend_rdy || (~dend_vld && ~next_syn);
end

logic next_syn;
always_ff @(posedge clk) begin

    if(reset || clear_act || clear_config) begin
        syn_addr_reg <= 0;
        dend_addr    <= 0;
        dend_charge  <= 0;
        dend_vld     <= 0;
        next_syn     <= 0;
    end
    else if(enable) begin
        if(dend_rdy && dend_vld) begin
            dend_vld <= 0;
            next_syn <= 0;
        end

        if(next_syn) begin
            dend_addr   <= dend_addr_temp;
            dend_charge <= dend_ch_temp;
            dend_vld    <= 1;
            next_syn    <= 0;
        end
        
        if(syn_rdy && syn_vld) begin
            syn_addr_reg <= syn_addr;
            next_syn     <= 1;
        end
        else if(dend_vld && ~dend_rdy) begin
            next_syn     <= 0;
        end
    end
end

always_ff @(posedge clk) begin
    step_done <= ~dend_vld && ~syn_vld && ~next_syn;
end

endmodule

`endif
