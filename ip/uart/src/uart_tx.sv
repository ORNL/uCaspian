/*
 * Copyright 2021 Brett Witherspoon
 */

`default_nettype none

module uart_tx #(
    parameter int unsigned PRESCALER = 48
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       valid,
    input  logic [7:0] data,
    output logic       ready,
    output logic       tx = '1
);
  logic [$clog2(PRESCALER)-1:0] cycle = '0;
  logic pulse;
  
  logic [9:0] shift = '1;
  logic [$clog2(10)-1:0] count = '0;

  assign pulse = cycle == '0;

  assign ready = count == '0;

  always_ff @(posedge clk) begin
    if (reset) begin
      shift <= '1;
      tx <= '1;
      count <= '0;
      cycle <= PRESCALER[$bits(cycle)-1:0] - 1'b1;
    end else if (ready) begin
      if (valid) begin
        shift <= {1'b1, data, 1'b0};
        count <= count + 1'b1;
        cycle <= PRESCALER[$bits(cycle)-1:0] - 1'b1;
      end
    end else if (pulse) begin
      {shift, tx} <= {1'b1, shift};
      if (count == $bits(shift)) begin
        count <= '0;
      end else begin
        count <= count + 1'b1;
      end
      cycle <= PRESCALER[$bits(cycle)-1:0] - 1'b1;
    end else begin
      cycle <= cycle - 1'b1;
    end
  end


`ifdef FORMAL
  initial assume (!valid);
  always @(posedge clk) begin
    if (!$initstate && $past(valid) && !$past(ready)) begin
      assume ($stable(valid));
      assume ($stable(data));
    end
  end

  assert property (count <= $bits(shift));

  assert property (cycle < PRESCALER);

  assert property (count > 0 || !ready);

  logic [7:0] buff;
  always @(posedge clk) begin
    if (valid && ready) begin
      buff <= data;
    end
  end

  always @(posedge clk) begin
    case (count)
      0: assert (tx == 1'b1);
      1: assert (tx == 1'b1);
      2: assert (tx == 1'b0);
      3: assert (tx == buff[0]);
      4: assert (tx == buff[1]);
      5: assert (tx == buff[2]);
      6: assert (tx == buff[3]);
      7: assert (tx == buff[4]);
      8: assert (tx == buff[5]);
      9: assert (tx == buff[6]);
      10: assert (tx == buff[7]);
      default: assert (0);
    endcase
  end

`endif

endmodule
