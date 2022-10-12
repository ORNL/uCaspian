// Description:
//   1 bit synchronizer based of n flip-flops for clock-domain crossings.
//   drive constant `data_in` to use as a reset synchronizer

module synchronizer(
    input  reset,
    input  clk,
    input  data_in,
    output data_out
);
parameter RESET_VALUE = 0;
parameter NUM_FLIP_FLOPS = 2;

//synchronizer chain of flip-flops
logic [NUM_FLIP_FLOPS-1:0] sync_chain = {RESET_VALUE};

always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
        sync_chain <= {RESET_VALUE};
    end
    else begin
        sync_chain <= {sync_chain[NUM_FLIP_FLOPS-2:0],  data_in};
    end
end

always_comb data_out <= sync_chain[NUM_FLIP_FLOPS-1];

endmodule
