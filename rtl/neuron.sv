/* uCaspian Neuron
 * Parker Mitchell, 2019
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
logic [11:0] config_ram [255:0];

// Load Configuration
logic [7:0] cfg_clear_addr;
logic [7:0] cfg_thresh;
logic cfg_clear_start;
logic cfg_clear_done;
always_ff @(posedge clk) begin
    if(clear_config) begin
        if(!cfg_clear_start) begin
            cfg_clear_start <= 1;
            cfg_clear_addr  <= 0;
        end
        else if(!cfg_clear_done) begin
            cfg_clear_addr <= cfg_clear_addr + 1;
            config_ram[cfg_clear_addr] <= 0;

            if(cfg_clear_addr == 255) begin
                cfg_clear_done  <= 1;
            end
        end
    end
    else begin 
        cfg_clear_start <= 0;
        cfg_clear_done  <= 0;

        if(config_enable) begin
            case(config_byte)
                1: cfg_thresh <= config_value[7:0];
                2: config_ram[config_addr] <= {config_value[3:0], cfg_thresh};
            endcase
        end
    end
end

// Store charge
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

// TODO: Store time of last fire for leak calculation
/*
dp_ram_16x256 last_fire_ram_inst(
    .clk(clk),
    .reset(reset),

    .rd_addr(),
    .rd_data(),
    .rd_en(),

    .wr_addr(),
    .wr_data(),
    .wr_en()
);
*/

// TODO: Optimize this somewhat -- it is blatently bad now
// It should be properly pipelined to maximize throughput

localparam [2:0]
    NEURON_IDLE   = 0,
    NEURON_READ   = 1,
    NEURON_WRITE  = 2,
    NEURON_FIRE   = 3,
    NEURON_OUTPUT = 4,
    NEURON_CLEAR  = 5;

logic [2:0] neuron_state;

logic [7:0] cur_addr;
logic [11:0] cur_config;
logic signed [15:0] accum_charge;
logic signed [15:0] in_charge;

always_comb begin
    accum_charge = $signed(charge_rd_data) + $signed(in_charge);
end

logic clear_act_done;

always_ff @(posedge clk) begin
    charge_rd_en <= 0;
    charge_wr_en <= 0;
    neuron_state <= neuron_state;
    step_done    <= 0;
    neuron_rdy   <= 0;
    clear_act_done <= 0;

    if(reset) begin
        neuron_rdy   <= 0;
        output_vld   <= 0;
        neuron_state <= NEURON_IDLE;
    end
    else begin
        case(neuron_state)
            NEURON_IDLE: begin
                neuron_rdy <= 1;
                step_done  <= 1; // TODO

                if(clear_act || clear_config) begin
                    cur_addr     <= 0;
                    neuron_rdy   <= 0;
                    step_done    <= 0;
                    neuron_state <= NEURON_CLEAR;
                end
                else if(neuron_rdy && neuron_vld) begin
                    cur_addr     <= neuron_addr;
                    in_charge    <= neuron_charge;
                    step_done    <= 0; // TODO

                    // if there is something to do 
                    if(neuron_charge != 0) begin
                        neuron_rdy     <= 0; 
                        charge_rd_addr <= neuron_addr;
                        charge_rd_en   <= 1;
                        neuron_state   <= NEURON_READ;
                    end
                end
            end
            NEURON_READ: begin
                step_done      <= 0;
                charge_rd_en   <= 1;
                cur_config     <= config_ram[cur_addr];
                neuron_state   <= NEURON_WRITE;
            end
            NEURON_WRITE: begin
                step_done      <= 0;
                charge_wr_addr <= cur_addr;
                charge_wr_en   <= 1;

                if($signed(accum_charge) > $signed({8'd0, cur_config[7:0]})) begin
                    charge_wr_data <= 0;
                    neuron_state   <= NEURON_FIRE;
                end
                else begin
                    charge_wr_data <= accum_charge;
                    neuron_state   <= NEURON_IDLE;
                end
            end
            NEURON_FIRE: begin
                axon_addr <= cur_addr;
                axon_vld  <= 1;
                step_done <= 0;

                if(axon_vld && axon_rdy) begin
                    axon_vld <= 0;

                    if(cur_config[11])
                        neuron_state <= NEURON_OUTPUT;
                    else 
                        neuron_state <= NEURON_IDLE;
                end
            end
            NEURON_OUTPUT: begin
                output_addr <= cur_addr;
                output_vld  <= 1;
                step_done   <= 0;

                if(output_vld && output_rdy) begin
                    output_vld   <= 0;
                    neuron_state <= NEURON_IDLE;
                end
            end
            NEURON_CLEAR: begin
                if(!clear_act && !clear_config) begin
                    neuron_state <= NEURON_IDLE;
                end
                else if(!clear_act_done) begin
                    charge_wr_addr <= cur_addr;
                    charge_wr_data <= 0;
                    charge_wr_en   <= 1;
                    cur_addr       <= cur_addr + 1;

                    if(cur_addr == 255) begin
                        clear_act_done <= 1;
                    end
                end
                else begin
                    clear_act_done <= 1;
                end
            end
            default: begin
                neuron_state <= NEURON_IDLE;
                step_done    <= 0;
            end
        endcase

        if((clear_act || clear_config) && neuron_state != NEURON_CLEAR) begin
            axon_vld     <= 0;
            neuron_rdy   <= 0;
            output_vld   <= 0;
            cur_addr     <= 0;
            neuron_state <= NEURON_CLEAR;
        end
    end
end

always_ff @(posedge clk) begin
    if(clear_act)
        clear_done <= clear_act_done;
    else if(clear_config)
        clear_done <= clear_act_done && cfg_clear_done;
    else
        clear_done <= 0;
end

// TODO: Periodically check if neuron has leaked to zero

endmodule

`endif
