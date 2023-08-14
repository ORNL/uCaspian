/*
 * Copyright 2021 Brett Witherspoon
 */

`timescale 1ns / 1ps

module uart_tb #(
    parameter real BAUD_RATE = 115200,
    parameter real CLOCK_FREQ = 12e6,
    localparam int unsigned PRESCALER = CLOCK_FREQ / BAUD_RATE
);
  int seed;

  logic clk;
  logic reset = '0;
  logic rx;
  logic rx_ready = '0;
  logic rx_valid;
  logic [7:0] rx_data;
  logic [7:0] tx_data;
  logic tx_valid;
  logic tx_ready;
  logic tx;

  clock_gen #(.CLOCK_FREQ(CLOCK_FREQ)) clock_gen_0 (.clk);

  uart #(
      .PRESCALER(PRESCALER)
  ) dut (
      .clk,
      .reset,
      .rx,
      .rx_ready,
      .rx_valid,
      .rx_data,
      .tx_data,
      .tx_valid,
      .tx_ready,
      .tx
  );

  assign rx = tx;

  byte sent = '0;
  byte rcvd = '1;

  task sync_reset(input integer hold = 2);
    begin
      @(negedge clk) reset = ~reset;
      repeat (hold) @(posedge clk);
      #1 reset = ~reset;
    end
  endtask : sync_reset

  task timeout;
    #(10000 / BAUD_RATE / 1e-9) $fatal(1, "Timeout");
  endtask : timeout

  initial begin : main
    if ($test$plusargs("vcd")) begin
      $dumpfile("uart_tb.vcd");
      $dumpvars(0, dut);
    end
    if (!$value$plusargs("seed=%d", seed)) begin
      seed = 0;
    end
    $info("Seed: %0d", seed);
    sync_reset();
    repeat (100) begin
`ifdef __ICARUS__
      sent = $urandom(seed);
`else
      randomize(sent);
`endif
`ifndef __ICARUS__
      fork
        timeout;
      join_none
`endif
      fork
        begin : send
          tx_valid = '1;
          tx_data = sent;
          do wait(tx_ready) @(posedge clk); while (!tx_ready);
          #1 tx_valid = '0;
        end : send
        begin : recv
          rx_ready = '1;
          wait(rx_valid) @(posedge clk) assert (rx_valid);
          rcvd = rx_data;
          #1 rx_ready = '0;
        end : recv
      join
`ifndef __ICARUS__
      disable timeout;
`endif
      assert (sent == rcvd) $info("recv: %2h == %2h", sent, rcvd);
      else $fatal(1, "Assertion violation: recv: %2h != %2h", sent, rcvd);
      @(negedge clk);
    end
    $fclose($fopen("uart_tb.pass", "w"));
    repeat (1000) @(posedge clk);
    $finish;
  end : main

endmodule : uart_tb
