/* uCaspian Dendrte
 * Parker Mitchell, 2019
 *
 * This implements the dendrite component. Dendrites are 
 * responsible for accumulating charge from synapse fires
 * based upon the synapse's configurated weight value.
 * At the start of every time step, the dendrite flushes
 * all accumulated charge to the neuron.
 */
`ifndef uCaspian_Dendrite_SV
`define uCaspian_Dendrite_SV

`include "dp_ram.sv"
`include "find_set_bit.sv"

module ucaspian_dendrite(
    input               clk,
    input               reset,
    input               enable,
    
    input               clear_act,
    input               clear_config,
    output logic        clear_done,

    // time sync
    input               next_step,
    output logic        step_done,

    // from synapse to dendrite
    input        [7:0]  dend_addr,
    input signed [8:0]  dend_charge,
    input               dend_vld,
    output logic        dend_rdy,

    // from dendrite to neuron
    output logic [7:0]  neuron_addr,
    output logic signed [15:0] neuron_charge,
    output logic        neuron_vld,
    input               neuron_rdy
);

// dual charge RAMs alternating based on timesteps
logic charge_ram_select;
logic clr_act_vec;

// select the right charge ram
always_ff @(posedge clk) begin
    clr_act_vec <= 0;

    if(reset) begin
        // init to opposite values
        charge_ram_select <= 0;
        clr_act_vec       <= 1;
    end
    else if(next_step) begin
        // swap every step
        charge_ram_select <= ~charge_ram_select;
        clr_act_vec       <= 1;
    end
end

// Charge RAM 0
logic [7:0]  ram_0_rd_addr;
logic [15:0] ram_0_rd_data;
logic        ram_0_rd_en;
logic [7:0]  ram_0_wr_addr;
logic [15:0] ram_0_wr_data;
logic        ram_0_wr_en;

dp_ram_16x256 charge_ram_inst_0(
    .clk(clk),
    .reset(reset),
    .rd_addr(ram_0_rd_addr),
    .rd_en(ram_0_rd_en),
    .rd_data(ram_0_rd_data),
    .wr_addr(ram_0_wr_addr),
    .wr_en(ram_0_wr_en),
    .wr_data(ram_0_wr_data)
);

// Charge RAM 1
logic [7:0]  ram_1_rd_addr;
logic [15:0] ram_1_rd_data;
logic        ram_1_rd_en;
logic [7:0]  ram_1_wr_addr;
logic [15:0] ram_1_wr_data;
logic        ram_1_wr_en;

dp_ram_16x256 charge_ram_inst_1(
    .clk(clk),
    .reset(reset),
    .rd_addr(ram_1_rd_addr),
    .rd_en(ram_1_rd_en),
    .rd_data(ram_1_rd_data),
    .wr_addr(ram_1_wr_addr),
    .wr_en(ram_1_wr_en),
    .wr_data(ram_1_wr_data)
);

// charge ram interfaces to data logic
logic [7:0]  incoming_rd_addr;
logic [15:0] incoming_rd_data;
logic        incoming_rd_en;
logic [7:0]  incoming_wr_addr;
logic [15:0] incoming_wr_data;
logic        incoming_wr_en;
logic [7:0]  outgoing_rd_addr;
logic [15:0] outgoing_rd_data;
logic        outgoing_rd_en;
logic [7:0]  outgoing_wr_addr;
logic [15:0] outgoing_wr_data;
logic        outgoing_wr_en;

// Mux the charge RAMs
always_comb begin
    if(!charge_ram_select) begin
        ram_0_rd_addr    = incoming_rd_addr;
        ram_0_rd_en      = incoming_rd_en;
        ram_0_wr_addr    = incoming_wr_addr;
        ram_0_wr_data    = incoming_wr_data;
        ram_0_wr_en      = incoming_wr_en;
        incoming_rd_data = ram_0_rd_data;

        ram_1_rd_addr    = outgoing_rd_addr;
        ram_1_rd_en      = outgoing_rd_en;
        ram_1_wr_addr    = outgoing_wr_addr;
        ram_1_wr_data    = outgoing_wr_data;
        ram_1_wr_en      = outgoing_wr_en;
        outgoing_rd_data = ram_1_rd_data;
    end
    else begin
        ram_1_rd_addr    = incoming_rd_addr;
        ram_1_rd_en      = incoming_rd_en;
        ram_1_wr_addr    = incoming_wr_addr;
        ram_1_wr_data    = incoming_wr_data;
        ram_1_wr_en      = incoming_wr_en;
        incoming_rd_data = ram_1_rd_data;

        ram_0_rd_addr    = outgoing_rd_addr;
        ram_0_rd_en      = outgoing_rd_en;
        ram_0_wr_addr    = outgoing_wr_addr;
        ram_0_wr_data    = outgoing_wr_data;
        ram_0_wr_en      = outgoing_wr_en;
        outgoing_rd_data = ram_0_rd_data;
    end
end

// Activity Vector
logic [15:0] activity_0;
logic [15:0] activity_1;

// Alias for the activity vectors
logic [15:0] activity_in;
logic [15:0] activity_out;
logic [15:0] activity_mask;

// Mux the activity 
always_ff @(posedge clk) begin
    if(clear_act || clear_config) begin
        activity_0 <= 0;
        activity_1 <= 0;
    end
    else if(!charge_ram_select) begin
        if(clr_act_vec)
            activity_0 <= 0;
        else
            activity_0 <= activity_0 | activity_in;

        activity_out <= activity_1;
    end
    else begin
        if(clr_act_vec)
            activity_1 <= 0;
        else
            activity_1 <= activity_1 | activity_in;

        activity_out <= activity_0;
    end
end

// Determine activity 
//   used to selectively flush dendrites to neurons
logic [3:0] activity_fb;
logic       activity_none;
find_set_bit_16 detect_act_inst(
    .in(activity_out & ~activity_mask),
    .out(activity_fb),
    .none_found(activity_none)
);

logic [1:0] activity_none_hold;
always_ff @(posedge clk) begin
    if(reset || next_step || clear_act || clear_config) begin
        activity_none_hold <= 0;
    end
    else begin
        activity_none_hold <= {activity_none, activity_none_hold[1]};
    end
end

// Accumulate from Synapse
logic accumulate_done;
logic signed [8:0] incoming_charge;
logic incoming_rd_dly;
logic [7:0] incoming_addr_dly;
logic signed [8:0] incoming_charge_dly;
always_ff @(posedge clk) begin
    if(!next_step && !clr_act_vec)
        dend_rdy <= 1;

    if(next_step) begin
        activity_in <= 0;
    end

    if(dend_rdy && dend_vld && ~clear_act && ~clear_config) begin
        incoming_rd_addr <= dend_addr;
        incoming_charge  <= dend_charge;
        incoming_rd_en   <= 1;
    end
    else begin
        incoming_rd_en   <= 0;
    end

    incoming_addr_dly   <= incoming_rd_addr;
    incoming_rd_dly     <= incoming_rd_en;
    incoming_charge_dly <= incoming_charge;
    incoming_wr_en      <= 0;

    if(clear_act || clear_config) begin
        incoming_wr_addr <= flush_idx;
        incoming_wr_data <= 0;
        incoming_wr_en   <= 1;
    end
    else if(incoming_rd_dly) begin
        incoming_wr_addr <= incoming_addr_dly; // incoming_rd_addr;
        //incoming_wr_data <= $signed(incoming_rd_data) + $signed(incoming_charge);
        incoming_wr_data <= $signed(incoming_rd_data) + $signed(incoming_charge_dly);
        incoming_wr_en   <= 1;
        activity_in[incoming_rd_addr[7:4]] <= 1;
    end

end

// Flush to Neuron
logic flush_done;

// TODO
always_comb begin
    step_done = flush_done && activity_none && (activity_none_hold == 2'b11) && (~incoming_rd_en && ~incoming_rd_dly && ~incoming_wr_en);
end

localparam [1:0]
    IDLE_ACTIVITY = 0,
    SCAN_ACTIVITY = 1,
    ITER_ACTIVITY = 2,
    DONE_ACTIVITY = 3;

logic [7:0] flush_idx;
logic [7:0] flush_last;
logic [1:0] flush_state;
logic       flush_start;
logic       flush_stop;
logic       flush_new;
logic       flush_ack;
logic [7:0] flush_idx_incr;

logic clear_act_start;
logic clear_act_end;

always_comb begin
    flush_idx_incr = flush_idx + 1;
end

always_ff @(posedge clk) begin
    outgoing_rd_en <= 0;
    outgoing_wr_en <= 0;
    clear_done     <= clear_config;
    clear_act_end  <= 0;

    if(reset) begin
        flush_idx     <= 0;
        flush_state   <= IDLE_ACTIVITY;
        flush_new     <= 0;
        flush_start   <= 0;
        flush_stop    <= 0;
        activity_mask <= 0;
        flush_done    <= 0;
        clear_act_start <= 1;
        clear_act_end   <= 0;
    end
    else if(clear_act || clear_config) begin
        // reset
        flush_state   <= IDLE_ACTIVITY;
        flush_new     <= 0;
        flush_start   <= 0;
        flush_stop    <= 0;
        flush_done    <= 0;
        activity_mask <= 0;
        flush_done    <= 0;


        outgoing_rd_en <= 0;
        outgoing_wr_en <= 1;
        outgoing_wr_addr <= flush_idx;

        if(clear_act_start && !clear_act_end) begin
            clear_act_start <= 0;
            flush_idx       <= 0;
        end
        else if(clear_act_end) begin
            flush_idx       <= 255;
            outgoing_wr_en  <= 0;
            clear_act_start <= 1;
            clear_act_end   <= 1;
            clear_done      <= 1;
        end
        else begin
            flush_idx <= flush_idx_incr;

            if(flush_idx == 255) begin
                clear_act_end <= 1;
            end
        end
    end
    else begin
        case(flush_state) 
            IDLE_ACTIVITY: begin
                flush_new  <= 0;
                flush_done <= 0;
                if(!clr_act_vec) begin
                    flush_state <= SCAN_ACTIVITY;
                end
            end
            SCAN_ACTIVITY: begin
                flush_new  <= 0;
                flush_done <= 0;
                if(activity_none && !clr_act_vec) begin
                    flush_done  <= 1;
                    flush_state <= DONE_ACTIVITY;
                end
                else if(!activity_none) begin
                    flush_idx   <= activity_fb << 4;
                    flush_last  <= (activity_fb << 4) + 15;
                    flush_start <= 1;
                    flush_state <= ITER_ACTIVITY;
                end
            end
            ITER_ACTIVITY: begin
                if(flush_ack && flush_stop) begin
                    outgoing_wr_addr <= flush_idx;
                    outgoing_wr_en   <= 1;
                    flush_new        <= 0;
                    flush_stop       <= 0;
                    flush_state      <= SCAN_ACTIVITY;
                    activity_mask[activity_fb] <= 1;
                end
                else if(flush_ack && !flush_start) begin
                    flush_idx        <= flush_idx_incr;
                    outgoing_rd_addr <= flush_idx_incr;
                    outgoing_rd_en   <= 1;
                    outgoing_wr_addr <= flush_idx;
                    outgoing_wr_en   <= 1;
                    flush_new        <= 1;
                    flush_start      <= 0;

                    if(flush_idx_incr == flush_last) begin
                        flush_stop <= 1;
                    end
                end
                else if(flush_start) begin
                    outgoing_rd_addr <= flush_idx;
                    outgoing_rd_en   <= 1;
                    flush_new        <= 1;
                    flush_start      <= 0;
                end
            end
            DONE_ACTIVITY: begin
                flush_new   <= 0;
                flush_done  <= 1;
                if(next_step) begin
                    activity_mask <= 0;
                    flush_state   <= IDLE_ACTIVITY;
                end
            end
        endcase
    end
end

always_ff @(posedge clk) begin
    neuron_vld <= 0;
    flush_ack  <= 0;

    if(flush_new && !flush_ack) begin
        neuron_vld <= 1;
    end
    
    if(neuron_vld && neuron_rdy) begin
        neuron_vld <= 0;
        flush_ack  <= 1;
    end
end

always_comb begin
    if(enable && !clear_act && !clear_config && !clear_config) begin
        neuron_charge = outgoing_rd_data;
    end
    else begin
        neuron_charge = 0;
    end
    
    neuron_addr = outgoing_rd_addr;
    outgoing_wr_data = 0;
end

endmodule

`endif
