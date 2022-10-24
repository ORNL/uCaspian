module divide_by_n(
	input clk,
	input reset,
	output reg out
);
	parameter N = 2;

	reg [$clog2(N)-1:0] counter;

	always @(posedge clk)
	begin
		out <= 0;

		if (reset)
			counter <= 0;
		else
		if (counter == 0)
		begin
			out <= 1;
			counter <= N - 1;
		end else
			counter <= counter - 1;
	end
endmodule