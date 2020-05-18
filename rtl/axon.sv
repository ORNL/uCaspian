/* uCaspian Axon
 * Parker Mitchell, 2020
 *
 * This module implements the 'axon' component. The axon is
 * responsible for both handling the mapping of neurons to 
 * synapses and providing axonal delay.
 */
`ifndef uCaspian_Axon_SV
`define uCaspian_Axon_SV

`include "dp_ram.sv"
`include "find_set_bit.sv"

module ucaspian_axon(
    input               clk,
    input               reset,
    input               enable,

    input               clear_act,
    input               clear_config,
    output logic        clear_done,

    // configuration
    input         [7:0] config_addr,
    input        [11:0] config_value,
    input         [2:0] config_byte,
    input               config_enable,

    // time sync
    input               next_step,
    output logic        step_done,

    // neuron -> axon
    input         [7:0] axon_addr,
    input               axon_vld,
    output logic        axon_rdy,

    // axon -> synapse
    output logic [11:0] syn_start,
    output logic [11:0] syn_end,
    output logic        syn_vld,
    input               syn_rdy
);

// Configuration RAM
//   [23:20] Delay cycles
//   [19:8]  First Synapse 
//   [7:0]   Number of synapses
logic  [7:0] config_rd_addr;
logic [23:0] config_rd_data;
logic        config_rd_en;
logic  [7:0] config_wr_addr;
logic [23:0] config_wr_data;
logic        config_wr_en;

dp_ram_24x256 config_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(config_rd_addr),
    .rd_data(config_rd_data),
    .rd_en(config_rd_en),

    .wr_addr(config_wr_addr),
    .wr_data(config_wr_data),
    .wr_en(config_wr_en)
);

// Delay RAM
//   Bitfield representing fires queue
logic [15:0] delay_rd_data;
logic  [7:0] delay_rd_addr;
logic        delay_rd_en;
logic [15:0] delay_wr_data;
logic  [7:0] delay_wr_addr;
logic        delay_wr_en;

dp_ram_16x256 delay_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(delay_rd_addr),
    .rd_data(delay_rd_data),
    .rd_en(delay_rd_en),

    .wr_addr(delay_wr_addr),
    .wr_data(delay_wr_data),
    .wr_en(delay_wr_en)
);

logic [7:0] config_clear_addr;
logic       config_clear_done;
logic       act_clear_done;

always_ff @(posedge clk) begin
    clear_done <= (clear_config && config_clear_done && act_clear_done) || (clear_act && act_clear_done); 
end

// Configuration & Clearing
//   This block owns the WRITE port for CONFIG
always_ff @(posedge clk) begin
    config_wr_en      <= 0;
    config_clear_addr <= 0;

    if(clear_config) begin
        config_clear_done <= 0;

        // clear addres counter (0 -> 255 & stop)
        if(config_clear_addr < 255) begin
            config_clear_addr <= config_clear_addr + 1;
        end
        else begin 
            config_clear_addr <= config_clear_addr;
            config_clear_done <= 1;
        end

        config_wr_addr <= config_clear_addr;
        config_wr_data <= 0;
        config_wr_en   <= 1;
    end
    else if(config_enable) begin
        config_wr_addr <= config_addr;
        
        case(config_byte)
            1: config_wr_data        <= 0;
            2: config_wr_data[23:20] <= config_value[7:4];
            3: config_wr_data[19:16] <= config_value[11:8];
            4: config_wr_data[15:8]  <= config_value[7:0];
            5: begin
                config_wr_data[7:0]  <= config_value[7:0];
                config_wr_en         <= 1;
            end
        endcase
    end
end

// actvity tracking
logic [15:0] activity;
logic [15:0] activity_next;
logic [15:0] activity_mask;
logic  [3:0] activity_fb;
logic        activity_none;

always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config) begin
        activity      <= 0;
        activity_next <= 0;
    end
    else if(next_step) begin
        activity      <= activity_next;
        activity_next <= 0;
    end
    else if(delay_wr_en && delay_wr_data != 0) begin
        activity_next[delay_wr_addr[7:4]] <= 1;
    end
end

find_set_bit_16 detect_act_inst(
    .in(activity & ~activity_mask),
    .out(activity_fb),
    .none_found(activity_none)
);

// shadow delay ram
logic [7:0]  dly_addr_1;
logic [7:0]  dly_addr_2;
logic [15:0] dly_data_1;
logic [15:0] dly_data_2;
logic [1:0]  dly_cn;
always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config || next_step) begin
        dly_addr_1 <= 0;
        dly_data_1 <= 0;
        dly_addr_2 <= 0;
        dly_data_2 <= 0;
        dly_cn     <= 0;
    end
    else if(delay_wr_en) begin
        dly_addr_1 <= delay_wr_addr;
        dly_data_1 <= delay_wr_data;
        dly_addr_2 <= dly_addr_1;
        dly_data_2 <= dly_data_1;
        if(dly_cn < 3) dly_cn <= dly_cn + 1;
    end
end

logic [15:0] delay_rd_data_1;
logic        delay_do_fwd;
always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config || next_step) begin
        delay_rd_data_1 <= 0;
        delay_do_fwd    <= 0;
    end
    if(delay_rd_en) begin
        if(delay_rd_addr == delay_wr_addr && delay_wr_en) begin
            delay_rd_data_1 <= delay_wr_data;
            delay_do_fwd    <= 1;
        end
        if(delay_rd_addr == dly_addr_1 && dly_cn > 0) begin
            delay_rd_data_1 <= dly_data_1;
            delay_do_fwd    <= 1;
        end
        else if(delay_rd_addr == dly_addr_2 && dly_cn > 1) begin
            delay_rd_data_1 <= dly_data_2;
            delay_do_fwd    <= 1;
        end
        else begin
            delay_do_fwd    <= 0;
        end
    end
end

logic delay_wr_flag;
always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config || next_step) begin
        delay_wr_flag <= 0;
    end
    else if(delay_wr_en) begin
        delay_wr_flag <= 1;
    end
end

// forward written value
logic [15:0] delay_rd_data_fwd;
always_comb begin
    if(delay_do_fwd) delay_rd_data_fwd = delay_rd_data_1;
    else delay_rd_data_fwd = delay_rd_data;
end

// Activity scan state
logic [7:0] scan_idx;
logic       scan_done;
logic       scan_iter;

// incoming -> process spike
logic [7:0] incoming_addr;
logic       incoming_spike; // 0 = activity scan, 1 = new spike
logic       incoming_vld;
logic       incoming_rdy;

logic       incoming_st_sp; // stall incoming spike
logic [3:0] st_cnt;

// Incoming fires and Activity Scan
always_ff @(posedge clk) begin
    // reset state
    if(reset || clear_config || clear_act || next_step) begin
        incoming_addr  <= 0;
        incoming_spike <= 0;
        incoming_vld   <= 0;
        scan_done      <= 0;
        scan_iter      <= 0;
        incoming_st_sp <= 0;
        st_cnt         <= 0;
        activity_mask  <= 0;
    end
    // stalled spike
    if(incoming_st_sp) begin
        if(incoming_addr != active_addr || (delay_wr_en && st_cnt > 1) || st_cnt > 7) begin
            incoming_spike <= 1;
            incoming_vld   <= 1;
            incoming_st_sp <= 0;
            st_cnt         <= 0;
        end

        if(st_cnt != 15) st_cnt <= st_cnt + 1;
    end
    // wait if we tried to send
    else if(incoming_vld && ~incoming_rdy) begin
        incoming_addr  <= incoming_addr;
        incoming_spike <= incoming_spike;
        incoming_vld   <= 1;
    end
    // Priority: Get incoming fires
    else if(axon_vld && axon_rdy) begin
        incoming_addr  <= axon_addr;

        if(axon_addr == incoming_addr || axon_addr == active_addr) begin
            incoming_st_sp <= 1;
            incoming_vld   <= 0;
            st_cnt         <= 0;
        end
        else begin
            incoming_spike <= 1;
            incoming_vld   <= 1;
        end
    end
    // Activity scan
    else if(~scan_done &&
            ~(scan_idx == incoming_addr && incoming_spike) &&
            ~(scan_idx == active_addr && active_spike)) begin

        if(scan_iter) begin
            scan_idx       <= scan_idx + 1;
            incoming_addr  <= scan_idx;
            incoming_spike <= 0;
            incoming_vld   <= 1;
            
            if(scan_idx[3:0] == 4'b1111) begin
                scan_iter <= 0;
            end
        end
        else if(~activity_none) begin
            scan_idx     <= {activity_fb, 4'b0000};
            scan_iter    <= 1;
            incoming_vld <= 0;

            activity_mask[activity_fb] <= 1;
        end
        else begin
            scan_done    <= 1;
            incoming_vld <= 0;
        end
    end
    // Do nothing
    else begin
        //incoming_addr  <= 0;
        incoming_spike <= 0;
        incoming_vld   <= 0; 
    end
end

// actively processing
logic [7:0] active_addr;
logic       active_spike;
logic       active_todo;

logic [7:0] last_active_addr;
logic       last_active_spike;

logic [7:0] last_scan_addr;
logic       scan_started;

// outgoing spikes -- axon -> spike dispatch
logic [7:0]  outgoing_addr;
logic [19:0] outgoing_config;
logic        outgoing_rdy;
logic        outgoing_vld;

// Load active address
always_ff @(posedge clk) begin
    // accept incoming data
    if(incoming_rdy && incoming_vld) begin
        active_addr  <= incoming_addr;
        active_spike <= incoming_spike;
        active_todo  <= 1;

        last_active_addr  <= active_addr;
        last_active_spike <= active_spike;
    end
    else if(incoming_rdy) begin
        active_todo  <= 0;
        active_spike <= 0;
    end
end

logic active_addr_will_shift;
logic [3:0] a_pre;

always_comb begin
    a_pre = active_addr[7:4];

    if(activity[a_pre]) begin
        if(activity_mask[a_pre]) begin
            if(scan_idx[7:4] == a_pre && scan_idx <= active_addr) begin
                active_addr_will_shift = 1;
            end
            else begin
                active_addr_will_shift = 0;
            end
        end
        else begin
            active_addr_will_shift = 1;
        end
    end
    else begin
        active_addr_will_shift = 0;
    end
end

logic [7:0] clear_addr;

// Process Spike (config lookup, delay)
always_ff @(posedge clk) begin

    // require explicit enable, reset every cycle
    delay_wr_en <= 0;

    // reset vld after successful transaction
    if(outgoing_vld && outgoing_rdy) outgoing_vld <= 0;

    if(reset || clear_act || clear_config || next_step) scan_started <= 0;
    
    if(~clear_act && ~clear_config) begin
        clear_addr     <= 0; 
        act_clear_done <= 0;
    end

    // Clear logic
    if(clear_act || clear_config) begin
        if(~act_clear_done) clear_addr <= clear_addr + 1; 
        if(clear_addr == 255) act_clear_done <= 1;
        
        delay_wr_addr <= clear_addr;
        delay_wr_data <= 0;
        delay_wr_en   <= ~act_clear_done;
    end

    // process spike
    if(incoming_rdy && active_todo) begin
        if(active_spike) begin
            if(config_rd_data[23:20] == 0) begin
                // No delay
                outgoing_addr   <= active_addr;
                outgoing_config <= config_rd_data[19:0];
                outgoing_vld    <= 1;
            end
            else begin
                if(delay_wr_addr == active_addr && delay_wr_flag) begin
                    delay_wr_data <= delay_wr_data | (1 << (config_rd_data[23:20]-1));
                end
                // write delay & determine if this has been shifted already
                else if(~active_addr_will_shift) begin

                    // this has already been shfited this timestep / won't be shifted later
                    delay_wr_data <= delay_rd_data_fwd | (1 << (config_rd_data[23:20]-1));
                end
                else begin
                    // this will shifted later this timestep
                    delay_wr_data <= delay_rd_data_fwd | (1 << (config_rd_data[23:20]));
                end

                delay_wr_addr <= active_addr;
                delay_wr_en   <= 1;
            end
        end
        // scan activity for a spike
        else begin
            last_scan_addr <= active_addr;
            scan_started   <= 1;
            
            delay_wr_addr <= active_addr;
            delay_wr_en   <= 1;

            // send for output
            if(delay_rd_data_fwd[0] == 1) begin
                outgoing_addr   <= active_addr;
                outgoing_config <= config_rd_data[19:0];
                outgoing_vld    <= 1;
            end
            delay_wr_data <= delay_rd_data_fwd >> 1;
        end
    end
end


always_comb config_rd_addr = incoming_addr;
always_comb delay_rd_addr  = incoming_addr;

always_comb config_rd_en = incoming_rdy && incoming_vld;
always_comb delay_rd_en  = incoming_rdy && incoming_vld;

// blocking all the way back
always_comb outgoing_rdy = ~syn_vld;
always_comb incoming_rdy = ~syn_vld;
always_comb axon_rdy     = ~syn_vld && ~incoming_st_sp;

// Output synapse ranges
always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config || (syn_vld && syn_rdy)) syn_vld <= 0;
    
    if(outgoing_rdy && outgoing_vld) begin
        if(outgoing_config[7:0] != 0) begin
            syn_start <= outgoing_config[19:8];
            syn_end   <= outgoing_config[19:8] + (outgoing_config[7:0] - 1);
            syn_vld   <= 1;
        end
    end
end

// STEP DONE logic
always_ff @(posedge clk) begin
    step_done <= scan_done && outgoing_rdy && ~outgoing_vld && ~incoming_vld && ~axon_vld && ~incoming_st_sp;
end

endmodule
`endif
