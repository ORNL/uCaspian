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
always_comb begin
    scfg_temp = synapse_cfg[syn_addr_reg];
end

always_ff @(posedge clk) begin
    // default to keep the same state
    synapse_state <= synapse_state;
    step_done     <= 0;

    case(synapse_state)
        SYN_IDLE: begin
            dend_vld  <= 0;
            syn_rdy   <= 0;
            step_done <= 1;

            if(enable && !cfg_enable) begin
                // read in a new fire
                syn_rdy       <= 1;
                if(syn_rdy && syn_vld) begin
                    step_done     <= 0;
                    synapse_state <= SYN_ACTIVE;
                    syn_addr_reg  <= syn_addr;
                    syn_rdy       <= 0;
                end
            end
            else begin
                synapse_state <= SYN_DISABLE;
            end
        end
        SYN_ACTIVE: begin
            // look up weight & target to pass to dendrite
            dend_addr   <= scfg_temp[7:0];
            dend_charge <= scfg_temp[15:8];
            dend_vld    <= 1;
            syn_rdy     <= 0;

            // wait for handshake signal
            if(dend_rdy) begin
                synapse_state <= SYN_IDLE;
            end
        end
        SYN_BLOCK_ON_DENDRITE: begin
            // not a thing right now
            synapse_state <= SYN_IDLE;
            syn_rdy       <= 0;
            dend_vld      <= 0;
        end
        SYN_DISABLE: begin
            dend_vld <= 0;
            syn_rdy  <= 0;

            if(enable && !cfg_enable) begin
                synapse_state <= SYN_IDLE;
            end
        end
    endcase

    // reset everything
    if(reset) begin
        synapse_state <= SYN_IDLE;
        syn_rdy       <= 0;
        dend_vld      <= 0;
        dend_addr     <= 0;
        dend_charge   <= 0;
        syn_addr_reg  <= 0;
        step_done     <= 0;
    end
end

endmodule

`endif
