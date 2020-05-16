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
//`include "find_set_bit.sv"

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

// Activity scan state
logic [7:0] scan_idx;
logic       scan_done;

// incoming -> process spike
logic [7:0] incoming_addr;
logic       incoming_spike; // 0 = activity scan, 1 = new spike
logic       incoming_vld;
logic       incoming_rdy;

// Incoming fires and Activity Scan
always_ff @(posedge clk) begin
    // reset state
    if(reset || clear_config || clear_act || next_step) begin
        incoming_addr  <= 0;
        incoming_spike <= 0;
        incoming_vld   <= 0;
        scan_done      <= 0; 
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
        incoming_spike <= 1;
        incoming_vld   <= 1;
    end
    // Activity scan
    else if(~scan_done) begin
        incoming_addr  <= scan_idx;
        incoming_spike <= 0;
        incoming_vld   <= 1;

        // Continue scan
        scan_idx <= scan_idx + 1;
        if(scan_idx == 255) begin
            scan_done <= 1;
        end
    end
    // Do nothing
    else begin
        incoming_addr  <= 0;
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
    active_todo <= 0;

    // accept incoming data
    if(incoming_rdy && incoming_vld) begin
        active_addr  <= incoming_addr;
        active_spike <= incoming_spike;
        active_todo  <= 1;

        last_active_addr  <= active_addr;
        last_active_spike <= active_spike;
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
    if(active_todo) begin
        if(active_spike) begin
            if(config_rd_data[23:20] == 0) begin
                // No delay
                outgoing_addr   <= active_addr;
                outgoing_config <= config_rd_data[19:0];
                outgoing_vld    <= 1;
            end
            else begin
                // write delay & determine if this has been shifted already
                if(active_addr < last_scan_addr && scan_started) begin
                    // this has already been shfited this timestep
                    delay_wr_data <= delay_rd_data | (1 << (config_rd_data[23:20]-1));
                end
                else if(active_addr == last_scan_addr && scan_started) begin
                    // this has already been shfited this timestep
                    delay_wr_data <= delay_wr_data | (1 << (config_rd_data[23:20]-1));
                end
                else begin
                    // this will shifted later this timestep
                    delay_wr_data <= delay_rd_data | (1 << (config_rd_data[23:20]));
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

            if(active_addr == last_active_addr) begin
                // send for output
                if(delay_wr_data[0] == 1) begin
                    outgoing_addr   <= active_addr;
                    outgoing_config <= config_rd_data[19:0];
                    outgoing_vld    <= 1;
                end
                delay_wr_data <= delay_wr_data >> 1;
            end
            else begin
                // send for output
                if(delay_rd_data[0] == 1) begin
                    outgoing_addr   <= active_addr;
                    outgoing_config <= config_rd_data[19:0];
                    outgoing_vld    <= 1;
                end
                delay_wr_data <= delay_rd_data >> 1;
            end
        end
    end
    
end

always_comb config_rd_addr = incoming_addr;
always_comb delay_rd_addr  = incoming_addr;

always_comb config_rd_en = incoming_rdy && incoming_vld;
always_comb delay_rd_en  = incoming_rdy && incoming_vld;

// blocking all the way back
always_comb outgoing_rdy = syn_rdy && !(syn_vld && syn_start != syn_end);
always_comb incoming_rdy = outgoing_rdy;
always_comb axon_rdy     = outgoing_rdy;

// Output synapse ranges
always_ff @(posedge clk) begin
    if(syn_vld && syn_rdy) syn_vld <= 0;
    
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
    step_done <= scan_done && outgoing_rdy && ~outgoing_vld && ~incoming_vld && ~axon_vld;
end

endmodule
`endif
