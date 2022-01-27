/* uCaspian
 * Parker Mitchell, 2019
 *
 * A neuromorphic "microcontroller" design with TENNLab integration.
 */
`ifndef uCaspian_SV
`define uCaspian_SV
/* verilator lint_off DECLFILENAME */

`include "packet_interface.sv"
`include "ucaspian_core.sv"

module ucaspian(
    input               sys_clk,
    input               reset,

    // TX
    output logic [7:0]  write_data,
    output logic        write_vld,
    input               write_rdy,

    // RX
    input        [7:0]  read_data,
    output logic        read_rdy,
    input               read_vld,

    output              led_0,
    output              led_1,
    output              led_2,
    output              led_3,
);

//////
// Signaling between packet interface and core
wire output_fire_waiting, cfg_done, metric_send, clear_done,
    time_update, core_active, time_target_ack, time_remaining;

wire output_fire_sent, ack_sent, time_sent, metric_read,
    input_fire_waiting, input_fire_ack, clear_act, clear_config,
    cfg_synapse, time_target_waiting;

wire [7:0]  output_fire_addr;
wire [31:0] time_current;
wire [7:0]  time_target_value;
wire [7:0]  input_fire_addr;
wire [7:0]  input_fire_value;
wire [2:0]  cfg_byte;
wire [11:0] cfg_addr;
wire [11:0] cfg_value;
wire [7:0]  metric_addr;
wire [7:0]  metric_value;

//////
// Packet Interface
//   Fetches and decodes variable length packets
//   Handles top-level control of the core
//   Configures the core
//   Relays fire & metric information back to the host
packet_interface pck_ctrl_inst(
    .clk(sys_clk),
    .reset(reset),

    .rx_packet_data(read_data),
    .rx_packet_vld(read_vld),
    .rx_packet_rdy(read_rdy),
    .tx_packet_data(write_data),
    .tx_packet_vld(write_vld),
    .tx_packet_rdy(write_rdy),

    .clear_act(clear_act),
    .clear_config(clear_config),
    .clear_done(clear_done),

    .ack_sent(ack_sent),
    .core_active(core_active),
    .led(led_3),

    .output_fire_addr(output_fire_addr),
    .output_fire_waiting(output_fire_waiting),
    .output_fire_sent(output_fire_sent),

    .input_fire_addr(input_fire_addr),
    .input_fire_value(input_fire_value),
    .input_fire_waiting(input_fire_waiting),
    .input_fire_ack(input_fire_ack),

    .time_remaining(time_remaining),
    .time_current(time_current),
    .time_update(time_update),
    .time_sent(time_sent),

    .time_target_value(time_target_value),
    .time_target_waiting(time_target_waiting),
    .time_target_ack(time_target_ack),

    .cfg_addr(cfg_addr),
    .cfg_value(cfg_value),
    .cfg_byte(cfg_byte),
    .cfg_synapse(cfg_synapse),
    .cfg_done(cfg_done),

    .metric_addr(metric_addr),
    .metric_value(metric_value),
    .metric_send(metric_send),
    .metric_read(metric_read)
);

// uCaspian Core
//   The "CPU" core of the design
//   Activity-driven execution of sparse SRNNs
//   Runtime configurable
ucaspian_core core(
    .clk(sys_clk),
    .reset(reset),
    .enable(1),

    .core_active(core_active),
    .ack_sent(ack_sent),

    .led_0(led_0),
    .led_1(led_1),
    .led_2(led_2),

    .output_fire_addr(output_fire_addr),
    .output_fire_waiting(output_fire_waiting),
    .output_fire_sent(output_fire_sent),

    .input_fire_addr(input_fire_addr),
    .input_fire_value(input_fire_value),
    .input_fire_waiting(input_fire_waiting),
    .input_fire_ack(input_fire_ack),

    .config_addr(cfg_addr),
    .config_type(cfg_synapse),
    .config_value(cfg_value),
    .config_byte(cfg_byte),
    .config_done(cfg_done),

    .clear_act(clear_act),
    .clear_config(clear_config),
    .clear_done(clear_done),

    .time_remaining(time_remaining),
    .time_current(time_current),
    .time_update(time_update),
    .time_sent(time_sent),

    .time_target_value(time_target_value),
    .time_target_waiting(time_target_waiting),
    .time_target_ack(time_target_ack),

    .metric_addr(metric_addr),
    .metric_value(metric_value),
    .metric_send(metric_send),
    .metric_read(metric_read)
);

endmodule

/* verilator lint_on DECLFILENAME */
`endif
