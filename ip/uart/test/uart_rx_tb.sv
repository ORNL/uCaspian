/*
 * Copyright 2021 Brett Witherspoon
 */

`timescale 1ns / 1ps

module uart_rx_tb #(
    parameter real BAUD_RATE = 115200,
    parameter real CLOCK_FREQ = 12e6,
    localparam int unsigned PRESCALER = CLOCK_FREQ / BAUD_RATE
);
  int seed;

  logic clk;
  logic reset = '0;
  logic [7:0] data;
  logic valid;
  logic ready = '0;
  logic rx = '1;

  clock_gen #(.CLOCK_FREQ(CLOCK_FREQ)) clock_gen_0 (.clk);

  uart_rx #(
      .PRESCALER(PRESCALER)
  ) dut (
      .clk,
      .reset,
      .rx,
      .ready,
      .valid,
      .data
  );

  byte sent = '0;
  byte rcvd = '1;

  task sync_reset(input integer hold = 2);
    begin
      @(negedge clk) reset = ~reset;
      repeat (hold) @(posedge clk);
      #1 reset = ~reset;
    end
  endtask : sync_reset

  task uart_send(input [7:0] data);
    begin
      rx = '0;
      #(1.0 / BAUD_RATE / 1e-9);
      for (int i = 0; i < 8; i++) begin
        rx = data[i];
        #(1.0 / BAUD_RATE / 1e-9);
      end
      rx = '1;
      #(1.0 / BAUD_RATE / 1e-9);
    end
  endtask : uart_send

  task timeout;
    #(10000 / BAUD_RATE / 1e-9) $fatal(1, "Timeout");
  endtask : timeout

  initial begin : main
    if ($test$plusargs("vcd")) begin
      $dumpfile("uart_rx_tb.vcd");
      $dumpvars(0, dut);
    end
    if (!$value$plusargs("seed=%d", seed)) begin
      seed = 0;
    end
    $info("Seed: %0d", seed);
    sync_reset();
    repeat (100) begin
      sent = $urandom;
      //randomize(sent);
      fork
        timeout;
      join_none
      fork
        uart_send(sent);
        begin : recv
          ready = '1;
          wait(valid) @(posedge clk) assert (valid);
          rcvd = data;
          #1 ready = '0;
        end : recv
      join
      disable timeout;
      assert (sent == rcvd) $info("recv: %2h == %2h", sent, rcvd);
      else $fatal(1, "Assertion violation: recv: %2h != %2h", sent, rcvd);
      @(negedge clk);
    end
    $fclose($fopen("uart_rx_tb.pass", "w"));
    repeat (1000) @(posedge clk);
    $finish;
  end : main

endmodule : uart_rx_tb
