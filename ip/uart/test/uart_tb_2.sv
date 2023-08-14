/*
 * Copyright 2021 Brett Witherspoon
 */

`timescale 1ns / 1ps

module uart_tb_2 #(
    parameter real BAUD_RATE = 115200,
    parameter real CLOCK_FREQ = 12e6,
    localparam int unsigned PRESCALER = CLOCK_FREQ / BAUD_RATE
);
  int seed;

  logic clk;
  logic reset = '0;
  logic rx = '1;
  logic rx_ready;
  logic rx_valid;
  logic [7:0] rx_data;
  logic [7:0] tx_data;
  logic tx_valid;
  logic tx_ready;
  logic tx;

  assign tx_data  = rx_data;
  assign tx_valid = rx_valid;
  assign rx_ready = tx_ready;

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

  task uart_recv(output logic [7:0] data);
    begin
      wait(tx === 0) #(1.5 / BAUD_RATE / 1e-9);
      for (int i = 0; i < 8; i++) begin
        data[i] = tx;
        #(1.0 / BAUD_RATE / 1e-9);
      end
    end
  endtask : uart_recv

  task timeout;
    #(10000 / BAUD_RATE / 1e-9) $fatal(1, "Timeout");
  endtask : timeout

  initial timeout;

  initial begin : main
    if ($test$plusargs("vcd")) begin
      $dumpfile("uart_tb_2.vcd");
      $dumpvars(0, dut);
    end
    if (!$value$plusargs("seed=%d", seed)) begin
      seed = 0;
    end
    $info("Seed: %0d", seed);
    sync_reset();
    repeat (100) begin
      sent = $urandom(seed);
      fork
        uart_send(sent);
        uart_recv(rcvd);
      join
      assert (sent == rcvd) $info("recv: %2h == %2h", sent, rcvd);
      else $fatal(1, "Assertion violation: recv: %2h != %2h", sent, rcvd);
    end
    disable timeout;
    $fclose($fopen("uart_tb_2.pass", "w"));
    repeat (1000) @(posedge clk);
    $finish;
  end : main

endmodule : uart_tb_2
