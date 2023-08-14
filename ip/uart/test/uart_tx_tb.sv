/*
 * Copyright 2021 Brett Witherspoon
 */

`timescale 1ns / 1ps

module uart_tx_tb #(
    parameter real BAUD_RATE = 115200,
    parameter real CLOCK_FREQ = 48e6,
    localparam int unsigned PRESCALER = CLOCK_FREQ / BAUD_RATE
);
  int seed;

  logic clk;
  logic reset = 0;
  logic [7:0] data;
  logic valid = 0;
  logic ready;
  logic tx;

  clock_gen #(.CLOCK_FREQ(CLOCK_FREQ)) clock_gen_u (.clk);

  uart_tx #(
      .PRESCALER(PRESCALER)
  ) dut (
      .clk,
      .reset,
      .data,
      .valid,
      .ready,
      .tx
  );

  byte sent, rcvd;

  task sync_reset(input integer hold = 2);
    begin
      @(negedge clk) reset = ~reset;
      repeat (hold) @(posedge clk);
      #1 reset = ~reset;
    end
  endtask : sync_reset

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

  initial begin : main
    if ($test$plusargs("vcd")) begin
      $dumpfile("uart_tx_tb.vcd");
      $dumpvars(0, dut);
    end
    if (!$value$plusargs("seed=%d", seed)) begin
      seed = 0;
    end
    $info("Seed: %0d", seed);
    valid = 0;
    sync_reset();
    repeat (100) begin
      sent = $urandom(seed);
      fork
        timeout;
      join_none
      fork
        begin : send
          valid = '1;
          data  = sent;
          do wait(ready) @(posedge clk); while (!ready);
          #1 valid = '0;
        end : send
        uart_recv(rcvd);
      join
      disable timeout;
      assert (sent == rcvd) $info("recv: %0d == %0d", sent, rcvd);
      else $fatal(1, "recv: %2h != %2h", sent, rcvd);
      @(negedge clk);
    end
    $fclose($fopen("uart_tx_tb.pass", "w"));
    repeat (1000) @(posedge clk);
    $finish;
  end : main

endmodule : uart_tx_tb
