/*
 * Copyright 2021 Brett Witherspoon
 */

`default_nettype none

module uart #(
    parameter int unsigned PRESCALER = 48
) (
    input  logic       clk,
    input  logic       reset,
    // Receiver
    input  logic       rx,
    input  logic       rx_ready,
    output logic       rx_valid,
    output logic [7:0] rx_data,
    // Transmitter
    input  logic [7:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready,
    output logic       tx
);
  uart_rx #(.PRESCALER(PRESCALER)) uart_rx_0(
    .clk,
    .reset,
    .rx,
    .ready(rx_ready),
    .valid(rx_valid),
    .data(rx_data)
  );

  uart_tx #(.PRESCALER(PRESCALER)) uart_tx_0(
    .clk,
    .reset,
    .tx,
    .valid(tx_valid),
    .data(tx_data),
    .ready(tx_ready)
  );

endmodule
