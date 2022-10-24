/*
 * Pulse stretcher.
 *
 * When the input goes high, the output goes high
 * for as long as the input is high, or as long as
 * it takes our timer to roll over- whichever is
 * longer.
 */
module pulse_stretcher(clk, reset, in, out);
   parameter BITS = 20;

   input  clk, reset, in;
   output out;
   reg    out;

   reg [BITS-1:0] counter;

   always @(posedge clk or posedge reset)
     if (reset) begin
        out <= 0;
        counter <= 0;
     end
     else if (counter == 0) begin
        out <= in;
        counter <= in ? 1 : 0;
     end
     else if (&counter) begin
        if (in) begin
           out <= 1;
        end
        else begin
           out <= 0;
           counter <= 0;
        end
     end
     else begin
        out <= 1;
        counter <= counter + 1;
     end
endmodule