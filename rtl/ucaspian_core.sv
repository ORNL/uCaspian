/* uCaspian Core
 * Parker Mitchell, 2019
 *
 * This is the core module responsible for performing
 * the acutal computation. It is designed to be paired with
 * an I/O interface and packet decoder to form a complete system.
 */
`ifndef uCaspian_Core_SV
`define uCaspian_Core_SV

/* Include all of the Core Components */
`include "synapse.sv"
`include "dendrite_mux.sv"
`include "dendrite.sv"
`include "neuron.sv"
`include "axon.sv"
`include "fire_dispatch.sv"

module ucaspian_core(
    input               clk,
    input               reset,
    input               enable,

    // misc control signals
    input               ack_sent,
    output logic        core_active,
    output logic        led_0,
    output logic        led_1,
    output logic        led_2,

    // clear state
    input               clear_act,
    input               clear_config,
    output logic        clear_done,

    // programming
    input        [11:0] config_addr,  // neuron: 8 bits, synapse: 12 bits
    input        [11:0] config_value,
    input        [2:0]  config_byte,
    input               config_type,  // 0 = neuron, 1 = synapse
    output logic        config_done,

    // metrics interface
    input        [7:0]  metric_addr,
    output logic [7:0]  metric_value,
    input               metric_read,
    output logic        metric_send,

    // input fire interface
    input        [7:0]  input_fire_addr,
    input        [7:0]  input_fire_value,
    input               input_fire_waiting,
    output logic        input_fire_ack,

    // output fire interface
    output logic [7:0]  output_fire_addr,
    output logic        output_fire_waiting,
    input               output_fire_sent,

    // target time
    input        [7:0]  time_target_value,
    input               time_target_waiting,
    output logic        time_target_ack,

    // current time
    output logic        time_remaining,
    output logic [31:0] time_current,
    output logic        time_update,
    input               time_sent
);

// specify if configuring a neuron or a synapse
wire config_synapse = (config_byte < 7) && config_type;
wire config_neuron  = (config_byte < 7) && !config_type;

// TODO
always_ff @(posedge clk) begin
    if(config_synapse && config_byte >= 3)
        config_done <= 1;
    else if(config_neuron && config_byte >= 5)
        config_done <= 1;
    else
        config_done <= 0;
end

logic next_time_step;
logic step_done;
logic step_done_hold;
logic [31:0] target_time;
logic [31:0] core_time;

// Network time counter
always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config) begin
        core_time      <= 0;
        next_time_step <= 0;
        time_remaining <= 0;
    end
    else begin
        // step through time
        if(step_done && step_done_hold && time_remaining && !next_time_step) begin
            next_time_step <= 1;
            time_update    <= 1;
            core_time      <= core_time + 1;
        end 
        else if(time_sent) begin
            time_update    <= 0;
        end

        if(next_time_step) begin
            next_time_step <= 0;
        end

        // determine if we are at the end of this run
        if(target_time > core_time) begin
            time_remaining <= 1;
        end
        else begin
            time_remaining <= 0;
        end
    end
end

always_comb time_current = core_time;

// Target time calculation
always_ff @(posedge clk) begin
    time_target_ack <= 0;

    if(reset || clear_act || clear_config) begin
        target_time <= 0;
    end
    else if(time_target_waiting && !time_target_ack) begin
        target_time     <= target_time + time_target_value;
        time_target_ack <= 1;
    end
end

// Indicate if the core is doing work
always_comb core_active = !clear_act && !clear_config && !reset && (time_remaining || (~time_remaining && ~step_done_hold));

// Synapses
logic [9:0] syn_addr [3:0];
logic       syn_vld  [3:0];
logic       syn_rdy  [3:0];

logic [7:0] syn_to_dend_addr   [3:0];
logic [7:0] syn_to_dend_charge [3:0];
logic       syn_to_dend_vld    [3:0];
logic       syn_to_dend_rdy    [3:0];

logic       syn_enable     [3:0];
logic       syn_cfg_enable [3:0];

// Determine synapse config enable signals
always_comb begin
    // default to not enabled
    syn_cfg_enable[0] = 0;
    syn_cfg_enable[1] = 0;
    syn_cfg_enable[2] = 0;
    syn_cfg_enable[3] = 0;

    if(config_synapse) begin
        // enable based on upper bits of synapse addr
        case(config_addr[11:10])
            0: syn_cfg_enable[0] = 1;
            1: syn_cfg_enable[1] = 1;
            2: syn_cfg_enable[2] = 1;
            3: syn_cfg_enable[3] = 1;
        endcase
    end
end

logic syn_step_done [3:0];
logic syn_clear_done [3:0];
logic synapse_step_done;
logic synapse_clear_done;
logic synapse_reset;

always_comb synapse_reset = reset || clear_act || clear_config;

genvar syn_i;
generate for(syn_i = 0; syn_i < 4; syn_i = syn_i + 1) begin : synapses

    always_comb syn_enable[syn_i] = !clear_act && !clear_config; // TODO

    ucaspian_synapse syn_inst(
        .clk(clk),
        .reset(synapse_reset),
        .enable(syn_enable[syn_i]),

        .clear_act(clear_act),
        .clear_config(clear_config),
        .clear_done(syn_clear_done[syn_i]),

        .step_done(syn_step_done[syn_i]),

        .cfg_addr(config_addr[9:0]),
        .cfg_value(config_value[7:0]),
        .cfg_byte(config_byte),
        .cfg_enable(syn_cfg_enable[syn_i]),

        .syn_addr(syn_addr[syn_i]),
        .syn_vld(syn_vld[syn_i]),
        .syn_rdy(syn_rdy[syn_i]),

        .dend_addr(syn_to_dend_addr[syn_i]),
        .dend_charge(syn_to_dend_charge[syn_i]),
        .dend_vld(syn_to_dend_vld[syn_i]),
        .dend_rdy(syn_to_dend_rdy[syn_i])
    );
end
endgenerate

always_comb begin
    synapse_step_done = syn_step_done[0] && syn_step_done[1] && syn_step_done[2] && syn_step_done[3];
    synapse_clear_done = syn_clear_done[0] && syn_clear_done[1] && syn_clear_done[2] && syn_clear_done[3];
end

logic [7:0] dend_in_addr;
logic [7:0] dend_in_charge;
logic dend_in_rdy, dend_in_vld;

// TODO
always_ff @(posedge clk) begin
    input_fire_ack <= 0;
    dend_in_vld    <= 0;

    if(clear_act || clear_config) begin
        dend_in_addr   <= 0;
        dend_in_charge <= 0;
        dend_in_vld    <= 0;
    end
    else if(input_fire_waiting && !input_fire_ack) begin
        dend_in_addr   <= input_fire_addr;
        dend_in_charge <= input_fire_value;
        dend_in_vld    <= 1;

        if(dend_in_vld && dend_in_rdy) begin
            dend_in_vld    <= 0;
            input_fire_ack <= 1;
        end
    end
end

logic [7:0] dend_addr;
logic signed [8:0] dend_charge;
logic dend_rdy, dend_vld;
logic dend_mux_reset;
logic dend_mux_enable;
always_comb dend_mux_reset = reset || clear_act || clear_config;
always_comb dend_mux_enable = ~clear_act && ~clear_config;

dendrite_mux dendrite_mux_inst(
    .clk(clk),
    .reset(dend_mux_reset),
    .enable(dend_mux_enable),

    // input fires go straight to the dendrite
    .incoming_addr(dend_in_addr),
    .incoming_charge(dend_in_charge),
    .incoming_vld(dend_in_vld),
    .incoming_rdy(dend_in_rdy),

    .syn_dend_addr_0(syn_to_dend_addr[0]),
    .syn_dend_addr_1(syn_to_dend_addr[1]),
    .syn_dend_addr_2(syn_to_dend_addr[2]),
    .syn_dend_addr_3(syn_to_dend_addr[3]),

    .syn_dend_charge_0(syn_to_dend_charge[0]),
    .syn_dend_charge_1(syn_to_dend_charge[1]),
    .syn_dend_charge_2(syn_to_dend_charge[2]),
    .syn_dend_charge_3(syn_to_dend_charge[3]),

    .syn_dend_vld_0(syn_to_dend_vld[0]),
    .syn_dend_vld_1(syn_to_dend_vld[1]),
    .syn_dend_vld_2(syn_to_dend_vld[2]),
    .syn_dend_vld_3(syn_to_dend_vld[3]),

    .syn_dend_rdy_0(syn_to_dend_rdy[0]),
    .syn_dend_rdy_1(syn_to_dend_rdy[1]),
    .syn_dend_rdy_2(syn_to_dend_rdy[2]),
    .syn_dend_rdy_3(syn_to_dend_rdy[3]),

    .dend_addr(dend_addr),
    .dend_charge(dend_charge),
    .dend_rdy(dend_rdy),
    .dend_vld(dend_vld)
);

logic [7:0] neuron_addr;
logic signed [15:0] neuron_charge;
logic neuron_rdy, neuron_vld;

logic dendrite_step_done;
logic dendrite_clear_done;
logic dendrite_enable;
always_comb dendrite_enable = ~clear_act && ~clear_config;

ucaspian_dendrite dendrite_inst(
    .clk(clk),
    .reset(reset),
    .enable(dendrite_enable),

    .clear_act(clear_act),
    .clear_config(clear_config),
    .clear_done(dendrite_clear_done),

    .next_step(next_time_step),
    .step_done(dendrite_step_done),

    .dend_addr(dend_addr),
    .dend_charge(dend_charge),
    .dend_rdy(dend_rdy),
    .dend_vld(dend_vld),

    .neuron_addr(neuron_addr),
    .neuron_charge(neuron_charge),
    .neuron_rdy(neuron_rdy),
    .neuron_vld(neuron_vld)
);

logic [7:0] axon_addr;
logic axon_rdy, axon_vld;

logic [7:0] neuron_output_addr;
logic neuron_output_rdy, neuron_output_vld;

logic neuron_clear_done;
logic neuron_step_done;
logic neuron_enable = ~clear_act && ~clear_config;
ucaspian_neuron neuron_inst(
    .clk(clk),
    .reset(reset),
    .enable(neuron_enable),

    .clear_act(clear_act),
    .clear_config(clear_config),
    .clear_done(neuron_clear_done),

    .next_step(next_time_step),
    .step_done(neuron_step_done),

    .config_addr(config_addr[7:0]),
    .config_value(config_value),
    .config_byte(config_byte),
    .config_enable(config_neuron),

    .neuron_addr(neuron_addr),
    .neuron_charge(neuron_charge),
    .neuron_vld(neuron_vld),
    .neuron_rdy(neuron_rdy),

    .output_addr(neuron_output_addr),
    .output_vld(neuron_output_vld),
    .output_rdy(neuron_output_rdy),

    .axon_addr(axon_addr),
    .axon_vld(axon_vld),
    .axon_rdy(axon_rdy)
);

// Fire output
always_ff @(posedge clk) begin

    // neuron_output handshake
    if(reset || clear_act || clear_config || output_fire_sent) begin
        neuron_output_rdy   <= 0;
    end
    else if(!output_fire_waiting) begin
        neuron_output_rdy   <= 1;
    end

    // output_fire flops
    if(reset || clear_act || clear_config || output_fire_sent) begin
        output_fire_waiting <= 0;
        output_fire_addr    <= 0;
    end
    else if(neuron_output_rdy && neuron_output_vld) begin
        output_fire_addr    <= neuron_output_addr;
        output_fire_waiting <= 1;
        neuron_output_rdy   <= 0;
    end
end

logic [11:0] axon_syn_start;
logic [11:0] axon_syn_end;
logic axon_syn_rdy, axon_syn_vld;

logic axon_clear_done;
logic axon_step_done;
logic axon_enable; // TODO
always_comb axon_enable = !clear_act && !clear_config;
ucaspian_axon axon_inst(
    .clk(clk),
    .reset(reset),
    .enable(axon_enable),

    .clear_act(clear_act),
    .clear_config(clear_config),
    .clear_done(axon_clear_done),

    .next_step(next_time_step),
    .step_done(axon_step_done),

    .config_addr(config_addr[7:0]),
    .config_value(config_value),
    .config_byte(config_byte),
    .config_enable(config_neuron),

    .axon_addr(axon_addr),
    .axon_vld(axon_vld),
    .axon_rdy(axon_rdy),

    .syn_start(axon_syn_start),
    .syn_end(axon_syn_end),
    .syn_vld(axon_syn_vld),
    .syn_rdy(axon_syn_rdy)
);

logic fd_step_done;
logic fd_reset; 
logic fd_enable;
always_comb begin
    fd_reset = reset || clear_act || clear_config;
    fd_enable = !fd_reset;
end
fire_dispatch fire_dispatch_inst(
    .clk(clk),
    .reset(fd_reset),
    .enable(fd_enable),

    .step_done(fd_step_done),

    .syn_start(axon_syn_start),
    .syn_end(axon_syn_end),
    .syn_in_vld(axon_syn_vld),
    .syn_in_rdy(axon_syn_rdy),

    .syn_rdy_0(syn_rdy[0]),
    .syn_rdy_1(syn_rdy[1]),
    .syn_rdy_2(syn_rdy[2]),
    .syn_rdy_3(syn_rdy[3]),

    .syn_vld_0(syn_vld[0]),
    .syn_vld_1(syn_vld[1]),
    .syn_vld_2(syn_vld[2]),
    .syn_vld_3(syn_vld[3]),

    .syn_addr_0(syn_addr[0]),
    .syn_addr_1(syn_addr[1]),
    .syn_addr_2(syn_addr[2]),
    .syn_addr_3(syn_addr[3])
);

// Metrics -- TODO: make this into a better module

logic [31:0] metric_acc_cnt;
logic [15:0] metric_fire_cnt;
logic [31:0] metric_clk_cnt;

logic [7:0]  metric_lst_addr;
logic        metric_lst_clear;

logic metric_send_reg;
always @(posedge clk) begin
    metric_send_reg <= 0;

    // accumulate count
    if(reset || clear_act || clear_config) begin
        metric_acc_cnt <= 0;
    end
    else if(dend_rdy && dend_vld) begin
        metric_acc_cnt <= metric_acc_cnt + 1;
    end

    // fire count
    if(reset || clear_act || clear_config) begin
        metric_fire_cnt <= 0;
    end
    else if(axon_rdy && axon_vld) begin
        metric_fire_cnt <= metric_fire_cnt + 1;
    end

    // active clock cycle count
    if(reset || clear_act || clear_config) begin
        metric_clk_cnt <= 0;
    end
    else if(core_active) begin
        metric_clk_cnt <= metric_clk_cnt + 1;
    end

    if(reset) begin
        metric_value     <= 0;
        metric_send_reg  <= 0;
        metric_lst_addr  <= 0;
        metric_lst_clear <= 0;
    end
    else if(metric_read) begin
        metric_value    <= metric_addr + 5;

        // TODO: clear after read
        case(metric_addr)
            1:  metric_value <= metric_fire_cnt[15:8]; 
            2:  metric_value <= metric_fire_cnt[7:0]; 

            3:  metric_value <= metric_acc_cnt[31:24];
            4:  metric_value <= metric_acc_cnt[23:16];
            5:  metric_value <= metric_acc_cnt[15:8];
            6:  metric_value <= metric_acc_cnt[7:0];

            7:  metric_value <= metric_clk_cnt[31:24];
            8:  metric_value <= metric_clk_cnt[23:16];
            9:  metric_value <= metric_clk_cnt[15:8];
            10: metric_value <= metric_clk_cnt[7:0];

            default: metric_value <= 0;
        endcase

        metric_send_reg  <= 1;
        metric_lst_addr  <= metric_addr;
        metric_lst_clear <= 1;
    end
    else if(metric_lst_clear) begin

        case(metric_lst_addr)
            2:  metric_fire_cnt <= 0;
            6:  metric_acc_cnt  <= 0;
            10: metric_clk_cnt  <= 0;
        endcase

        metric_lst_clear <= 0;
    end
end

always_comb metric_send = metric_send_reg && metric_read;

// Time stepping
always_comb step_done = fd_step_done && axon_step_done && neuron_step_done && dendrite_step_done && synapse_step_done && !output_fire_waiting;

always_ff @(posedge clk) step_done_hold <= step_done;

// red, green, blue
always_ff @(posedge clk) begin
    led_0 <= axon_syn_rdy;
    led_1 <= axon_syn_vld;
    led_2 <= fd_step_done;
end

logic logic_clear_done;
assign logic_clear_done = dendrite_clear_done && axon_clear_done && neuron_clear_done && synapse_clear_done;

// Clear ack logic
always_ff @(posedge clk) begin
    if(reset || ack_sent) begin
        clear_done <= 0;
    end
    else if((clear_act || clear_config) && logic_clear_done) begin
        clear_done <= 1;
    end
end

endmodule
`endif
