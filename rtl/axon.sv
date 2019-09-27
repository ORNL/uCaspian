/* uCaspian Axon
 * Parker Mitchell, 2019
 *
 * This module implements the 'axon' component. The axon is
 * responsible for both handling the mapping of neurons to 
 * synapses and providing axonal delay.
 */
`ifndef uCaspian_Axon_SV
`define uCaspian_Axon_SV

`include "find_set_bit_16.sv"

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
logic [23:0] config_ram [255:0];

// Delay RAM
//   Bitfield representing fires queued
logic [15:0] delay_ram [255:0];

// Activity Metadata
logic [15:0] activity;
logic  [3:0] activity_idx;
logic        activity_none;

initial activity = 0;

find_set_bit_16 meta_act_inst(
    .in(activity),
    .out(activity_idx),
    .none_found(activity_none)
);

// Clear configuration
logic [7:0] clear_addr;
logic clear_cfg_active, clear_cfg_done;
logic clear_act_done;
always_ff @(posedge clk) begin
    if(clear_config) begin
        if(!clear_cfg_active && !clear_cfg_done) begin
            clear_cfg_active <= 1;
            clear_addr      <= 0;
        end
        else if(clear_cfg_active && !clear_cfg_done) begin
            clear_addr <= clear_addr + 1;

            if(clear_addr == 255)
                clear_cfg_done <= 1;
        end
    end
    else begin
        clear_addr      <= 0;
        clear_cfg_done   <= 0;
        clear_cfg_active <= 0;
    end
end

// Load Configuration
logic [23:0] config_wr_data;
always_ff @(posedge clk) begin
    if(clear_config) begin
        config_ram[clear_addr] <= 0;
    end
    else if(config_enable) begin
        case(config_byte)
            2: config_wr_data[23:20]   <= config_value[7:4];
            3: config_wr_data[19:16]   <= config_value[3:0];
            4: config_wr_data[15:8]    <= config_value[7:0];
            5: config_ram[config_addr] <= {config_wr_data[23:8], config_value[7:0]};
        endcase
    end
end

// TODO: Clear activity
always_comb clear_act_done = clear_act || clear_config;

// TODO: Update activity

// TODO: Process activity

// TODO: Accept incoming fires -- using delay

// TODO: Output fires to synapses


// Placeholder
localparam [1:0] 
    AXON_WAIT_NEURON  = 0,
    AXON_READ         = 1,
    AXON_WAIT_SYNAPSE = 2;

logic [1:0]  axon_state;
logic [7:0]  cur_addr;

logic [23:0] config_line;
logic [11:0] ld_syn_start;
logic [8:0]  ld_syn_cnt;

always_ff @(posedge clk) begin
    step_done <= 0;

    if(reset || clear_act || clear_config) begin
        axon_state <= AXON_WAIT_NEURON;
        cur_addr   <= 0;
        axon_rdy   <= 0;
        syn_vld    <= 0;
    end
    else if(enable) begin
        case(axon_state)
            AXON_WAIT_NEURON: begin
                axon_rdy <= 1;

                if(axon_rdy && axon_vld) begin
                    cur_addr   <= axon_addr;
                    axon_rdy   <= 0;
                    axon_state <= AXON_READ;
                end
                else begin
                    // TODO
                    step_done <= 1;
                end
            end
            AXON_READ: begin
                //ld_syn_start <= config_ram[cur_addr][19:8];
                //ld_syn_cnt   <= config_ram[cur_addr][7:0];
                config_line  <= config_ram[cur_addr];
                axon_state   <= AXON_WAIT_SYNAPSE;
            end
            AXON_WAIT_SYNAPSE: begin

                if(config_line[7:0] == 2'h00) begin
                    axon_state <= AXON_WAIT_NEURON;
                end
                else begin
                    syn_vld   <= 1;
                    syn_start <= config_line[19:8];
                    syn_end   <= config_line[19:8] + (config_line[7:0] - 1);
                    
                    if(syn_rdy && syn_vld) begin
                        syn_vld    <= 0;
                        axon_state <= AXON_WAIT_NEURON;
                    end
                end
            end
            default: begin
                cur_addr   <= 0;
                axon_rdy   <= 0;
                syn_vld    <= 0;
                axon_state <= AXON_WAIT_NEURON;
            end
        endcase
    end
end

always_ff @(posedge clk) begin
    if(clear_act)
        clear_done <= clear_act_done;
    else if(clear_config)
        clear_done <= clear_act_done && clear_cfg_done;
    else
        clear_done <= 0;
end

endmodule

`endif
