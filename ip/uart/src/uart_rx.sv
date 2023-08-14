/*
 * Copyright 2021 Brett Witherspoon
 */

`default_nettype none

module uart_rx #(
    parameter int unsigned PRESCALER = 48
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,
    input  logic       ready,
    output logic       valid = '0,
    output logic [7:0] data
);
  localparam bit [$clog2(PRESCALER)-1:0] PERIOD = PRESCALER - 1;
  localparam bit [$clog2(10)-1:0] STOP = 10;

  logic rx_meta = '1;
  logic rx_sync = '1;

  logic [$clog2(PRESCALER)-1:0] cycle = '0;

  logic [7:0] shift = '1;
  logic [$clog2(10)-1:0] count = '0;

  always_ff @(posedge clk) begin
    if (reset) begin
      rx_meta <= '1;
      rx_sync <= '1;
    end else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
    end
  end

  // {* state *}
  always_ff @(posedge clk) begin
    if (count == '0) begin
      if (~rx_sync) begin
        count <= count + 1'b1;
        cycle <= PERIOD / 2;
      end
    end else if (cycle == PERIOD) begin
      if (count == STOP) begin
        count <= '0;
      end else begin
        shift <= {rx_sync, shift[$bits(shift)-1:1]};
        count <= count + 1'b1;
      end
      cycle <= '0;
    end else begin
      cycle <= cycle + 1'b1;
    end
    if (reset) begin
      count <= '0;
      cycle <= '0;
    end
  end
  // {* *}

  // {* valid *}
  always_ff @(posedge clk) begin
    if (cycle == PERIOD && count == STOP) begin
      if (!valid || ready) begin
        valid <= '1;
        data <= shift;
      end
    end else if (valid && ready) begin
      valid <= '0;
    end
    if (reset) begin
      valid <= '0;
    end
  end
  // {* *}

endmodule
