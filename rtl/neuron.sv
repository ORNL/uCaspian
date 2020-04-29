/* uCaspian Neuron
 * Parker Mitchell, 2020
 *
 * The Neuron module is responsible for maintaining charge values
 * between time steps, accumulating charge from dendrites, 
 * calculating and updating neuron charge leak, and determining
 * when a neuron should fire based upon a configurable threshold.
 */
`ifndef uCaspian_Neuron_SV
`define uCaspian_Neuron_SV

`include "dp_ram.sv"

module ucaspian_neuron(
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

    // dendrite -> neuron
    input         [7:0] neuron_addr,
    input signed [15:0] neuron_charge,
    input               neuron_vld,
    output logic        neuron_rdy,

    // output fires
    output logic  [7:0] output_addr,
    output logic        output_vld,
    input               output_rdy,

    // neuron -> axon
    output logic  [7:0] axon_addr,
    output logic        axon_vld,
    input               axon_rdy
);

// Configuration RAM
//     [11]  Output Enable
//   [10:8]  Charge Leak
//    [0:7]  Threshold
logic  [7:0] config_rd_addr;
logic [15:0] config_rd_data;
logic        config_rd_en;
logic  [7:0] config_wr_addr;
logic [15:0] config_wr_data;
logic        config_wr_en;

dp_ram_16x256 config_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(config_rd_addr),
    .rd_data(config_rd_data),
    .rd_en(config_rd_en),

    .wr_addr(config_wr_addr),
    .wr_data(config_wr_data),
    .wr_en(config_wr_en)
);

// Charge RAM -- stores current neuron charge
logic  [7:0] charge_rd_addr;
logic [15:0] charge_rd_data;
logic        charge_rd_en;
logic  [7:0] charge_wr_addr;
logic [15:0] charge_wr_data;
logic        charge_wr_en;

dp_ram_16x256 charge_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(charge_rd_addr),
    .rd_data(charge_rd_data),
    .rd_en(charge_rd_en),

    .wr_addr(charge_wr_addr),
    .wr_data(charge_wr_data),
    .wr_en(charge_wr_en)
);

// Fire Time RAM -- store last fire time for leak calculation
logic  [7:0] ftime_rd_addr;
logic [15:0] ftime_rd_data;
logic        ftime_rd_en;
logic  [7:0] ftime_wr_addr;
logic [15:0] ftime_wr_data;
logic        ftime_wr_en;

dp_ram_16x256 ftime_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(ftime_rd_addr),
    .rd_data(ftime_rd_data),
    .rd_en(ftime_rd_en),

    .wr_addr(ftime_wr_addr),
    .wr_data(ftime_wr_data),
    .wr_en(ftime_wr_en)
);

// bond all ram read port control together
logic [7:0] ram_rd_addr;
logic ram_rd_en;

assign ftime_rd_addr  = ram_rd_addr;
assign charge_rd_addr = ram_rd_addr;
assign config_rd_addr = ram_rd_addr;

assign ftime_rd_en  = ram_rd_en;
assign charge_rd_en = ram_rd_en;
assign config_rd_en = ram_rd_en;

logic block;

assign neuron_rdy = ~block;

// Stage 1: Register incoming charge, read from rams
logic signed [15:0] in_charge;
logic [7:0] in_addr;
always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config) begin
        in_charge   <= 0;
        in_addr     <= 0;
        ram_rd_addr <= 0;
        ram_rd_en   <= 0;
    end
    else if(neuron_vld && neuron_rdy) begin
        // Register data with handshake
        // The first step is to read config/charge
        in_charge   <= neuron_charge;
        in_addr     <= neuron_addr;
        ram_rd_addr <= neuron_addr;
        ram_rd_en   <= 1;
    end
    else begin
        ram_rd_en   <= 0;
    end
end

// This will synchronize the 1st stage with the 2nd stage
// even if there is a stall in the pipeline
logic stage_2_en;
always_ff @(posedge clk) begin
    if(ram_rd_en) stage_2_en <= 1;
    else if(block) stage_2_en <= stage_2_en;
    else stage_2_en <= 0;
end

// Stage 2: Accumulate charge // TODO: Leak
logic signed [15:0] accum_charge;
logic [7:0] accum_addr;
logic [7:0] accum_thresh;
logic accum_oe;
logic accum_en;

always_ff @(posedge clk) begin
    if(reset || clear_act || clear_config) begin
        accum_addr   <= 0;
        accum_charge <= 0;
        accum_thresh <= 0;
        accum_oe     <= 0;
        accum_en     <= 0;
    end
    else if(~block & stage_2_en) begin
        accum_addr   <= in_addr;
        accum_charge <= $signed(in_charge) + $signed(charge_rd_data);
        accum_thresh <= config_rd_data[7:0];
        accum_oe     <= config_rd_data[11];
        accum_en     <= 1;
    end
    else if(~block) begin
        accum_en     <= 0;
    end
end

// Stage 3: Determine if firing, write back charge, write back fire time
//   Also handles writing configuration data and clearing activity
logic does_fire;
logic output_en;
logic [7:0] fire_addr;
logic [7:0] config_thresh;
logic [7:0] clear_addr;

always_ff @(posedge clk) begin
    // pull to zero whenever not clearing stuff
    if(~clear_act && ~clear_config) begin
        clear_addr <= 0;
        clear_done <= 0;
    end

    charge_wr_en <= 0;
    config_wr_en <= 0;
    ftime_wr_en  <= 0;
    
    if(reset) begin
        does_fire <= 0;
        output_en <= 0;
        fire_addr <= 0;

        config_thresh <= 0;
        clear_addr    <= 0;
    end
    else if(config_enable) begin
        config_wr_addr <= config_addr;
        config_wr_en   <= 0;

        case(config_byte)
            1: config_thresh   <= config_value[7:0];
            2: begin
                config_wr_data <= {4'b0000, config_value[3:0], config_thresh};
                config_wr_en   <= 1;
            end
        endcase
    end
    else if(clear_act || clear_config) begin
        // reset state
        does_fire     <= 0;
        output_en     <= 0;
        fire_addr     <= 0;
        config_thresh <= 0;

        // clear address counter (0->255, then signal done)
        if(clear_addr == 255) clear_done <= 1;
        if(~clear_done) clear_addr <= clear_addr + 1;

        // if clearing config, do that at the same time as clear activity
        if(clear_config) begin
            config_wr_addr <= clear_addr;
            config_wr_data <= 0;
            config_wr_en   <= 0;
        end

        // clear activity for both cases
        charge_wr_addr <= clear_addr;
        charge_wr_data <= 0;
        charge_wr_en   <= ~clear_done;

        // TODO: track fire timing for leak
        // ftime_wr_addr  <= clear_addr;
        // ftime_wr_data  <= 0;
        // ftime_wr_en    <= 1;
    end
    else if(~block && accum_en) begin
        charge_wr_addr <= accum_addr;
        charge_wr_en   <= 1;

        // TODO: fire time stuff
        // ftime_wr_addr <= accum_addr;
        // ftime_wr_data <= time + 1;
        // ftime_wr_en   <= 1;

        // FIRE!
        if(accum_charge > $signed({8'd0, accum_thresh})) begin
            charge_wr_data <= 0;
            does_fire      <= 1;
            output_en      <= accum_oe;
            fire_addr      <= accum_addr;
        end
        else begin
            // If we don't fire, then write back the residual charge
            charge_wr_data <= accum_charge;
            does_fire      <= 0;
        end
    end
    else if(~block) begin
        // reset 'does_fire' after data is passed on 
        if((output_en && output_rdy && axon_rdy) || (~output_en && axon_rdy))
            does_fire <= 0;
    end
end


// Stage 4: Output fire if necessary
always_ff @(posedge clk) begin
    axon_vld   <= 0;
    output_vld <= 0;

    if(reset) begin
        block <= 0;
    end
    else if(clear_config || clear_act) begin
        block <= 1;
    end
    else if(does_fire) begin
        // we sent the fire, drop vld back low
        if(axon_vld) begin
            axon_vld    <= 0;
            output_vld  <= 0;
        end
        // we can send the fire, so lets do it
        else if(output_en && output_rdy && axon_rdy) begin
            output_addr <= fire_addr;
            output_vld  <= 1;
            axon_addr   <= fire_addr;
            axon_vld    <= 1;
            block       <= 0;
        end
        // not an output neuron, so it just needs to go to the axon
        else if(~output_en && axon_rdy) begin
            axon_addr <= fire_addr;
            axon_vld  <= 1;
            block     <= 0;
        end
        // unable to send the fire, block the pipeline
        else begin
            block <= 1;
        end
    end
    else begin
        block <= 0;
    end
end

// indicate when we are working
always_ff @(posedge clk) begin
    step_done <= ~block && ~neuron_vld && ~charge_wr_en && ~ram_rd_en && ~stage_2_en && ~accum_en;
end

endmodule
`endif
