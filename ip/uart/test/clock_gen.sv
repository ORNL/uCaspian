// Copyright 2021 Brett Witherspoon

`timescale 1ns / 1ps

// See "SystemVerilog Event Regions, Race Avoidance & Guidelines" by Clifford E. Cummings
module clock_gen #(
  parameter real CLOCK_FREQ = 100e6,
  localparam real CLOCK_UNIT = 1e-9,
  localparam real CLOCK_PERIOD  = 1.0 / CLOCK_FREQ / CLOCK_UNIT
) (
  output logic clk
);
  initial begin
    clk <= '0;
    forever #(CLOCK_PERIOD / 2) clk = ~clk;
  end
endmodule