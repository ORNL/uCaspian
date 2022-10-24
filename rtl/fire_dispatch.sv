/* uCaspian Fire Dispatch
 * Parker Mitchell, 2019
 *
 * This module serves to handle dispatching fires from an axon
 * to all of the downstream synapses. It must handle several
 * parallel synapse units coherently -- ideally maximizing utilization.
 */

/* A note: The ports are not represented as an unpacked vector
 * for synthesis compatibility reasons. It is easier to just
 * not do it than to deal with the fallout from bad synthesis tools.
 */

module fire_dispatch(
    input               clk,
    input               reset,
    input               enable,

    output logic        step_done,

    // axon -> fire dispatch
    input        [11:0] syn_start,
    input        [11:0] syn_end,
    output logic        syn_in_rdy,
    input               syn_in_vld,

    output logic        syn_vld_0,
    output logic        syn_vld_1,
    output logic        syn_vld_2,
    output logic        syn_vld_3,

    output logic  [9:0] syn_addr_0,
    output logic  [9:0] syn_addr_1,
    output logic  [9:0] syn_addr_2,
    output logic  [9:0] syn_addr_3,

    input               syn_rdy_0,
    input               syn_rdy_1,
    input               syn_rdy_2,
    input               syn_rdy_3
);

logic [11:0] last_idx;
logic [11:0] cur_idx;
logic iterating;
logic cur_syn_vld;
logic cur_syn_rdy;

always_comb begin
    syn_addr_0 = cur_idx[9:0];
    syn_addr_1 = cur_idx[9:0];
    syn_addr_2 = cur_idx[9:0];
    syn_addr_3 = cur_idx[9:0];

    syn_vld_0  = 0;
    syn_vld_1  = 0;
    syn_vld_2  = 0;
    syn_vld_3  = 0;

    unique case(cur_idx[11:10])
        0: begin
            cur_syn_rdy = syn_rdy_0;
            syn_vld_0   = cur_syn_vld;
        end
        1: begin
            cur_syn_rdy = syn_rdy_1;
            syn_vld_1   = cur_syn_vld;
        end
        2: begin
            cur_syn_rdy = syn_rdy_2;
            syn_vld_2   = cur_syn_vld;
        end
        3: begin
            cur_syn_rdy = syn_rdy_3;
            syn_vld_3   = cur_syn_vld;
        end
    endcase
end

always_ff @(posedge clk) begin
    // default values
    cur_syn_vld <= 0;
    step_done   <= 1;

    if(reset) begin
        iterating <= 0;
        last_idx  <= 0;
        cur_idx   <= 0;
    end
    if(enable) begin

        if(iterating) begin
            // push one index at a time
            cur_syn_vld <= 1;
            step_done   <= 0;

            if(cur_syn_rdy && cur_syn_vld) begin
                if(cur_idx == last_idx) begin
                    // stop condition
                    iterating   <= 0;
                    last_idx    <= 0;
                    cur_idx     <= 0;
                    cur_syn_vld <= 0;
                    syn_in_rdy  <= 1; // ready for more!
                end
                else begin
                    // keep iterating
                    cur_idx <= cur_idx + 1;
                end
            end
        end
        else begin
            syn_in_rdy <= 1;

            if(syn_in_rdy && syn_in_vld) begin
                last_idx   <= syn_end;
                cur_idx    <= syn_start;
                iterating  <= 1;
                syn_in_rdy <= 0;
                step_done  <= 0;
            end
        end
    end
end

endmodule
