/* uCaspian for Lattice ice40
 * Parker Mitchell, 2020
 *
 * Build Tools: Project Icestorm + Yosys + NextPnR
 * Board: Dev Board r0
 * FPGA: Lattice ice40up5k
 * Comm Interface: FTDI 2232H USB Bridge
 */
`include "ucaspian.sv"
`include "util.sv"
`include "axi_stream/axis_ft245.sv"
`include "axi_stream/axis_fifo.v"

module top(
    input  clk_i, 

    /* bidirectional, asynchronous data bus */
    inout  d0,
    inout  d1,
    inout  d2,
    inout  d3,
    inout  d4,
    inout  d5,
    inout  d6,
    inout  d7,

    /* comm flags */
    input  txe,
    input  rxf,
    output rd,
    output wr,
    output oe,
    output siwua,

    output led1,
    output led2,
    output led3,
    output led4
);

    // system clock
    logic clk;
    logic locked;

    // Just use 25 MHz for now
    assign clk = clk_i;
    assign locked = 1;

    /*
    // Generate 30 MHz clock from the 25 MHz oscillator
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
	.DIVR(4'b0001),		// DIVR =  1
	.DIVF(7'b1001100),	// DIVF = 76
	.DIVQ(3'b101),		// DIVQ =  5
	.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
    ) uut (
        .LOCK(locked),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_i),
        .PLLOUTCORE(clk)
    );
    */

    // system reset
    logic [2:0] reset_cnt;
    logic reset;
    initial reset = 1;
    initial reset_cnt = 3'b111;

    always_ff @(posedge clk) begin
        if(reset_cnt > 0 && locked) begin
            reset_cnt <= reset_cnt - 1;
            reset     <= 1;
        end
        else if(reset_cnt != 0 && ~locked) begin
            reset     <= 1;
        end
        else begin
            reset     <= 0;
        end
    end

    //// FTDI Async FIFO ////
    logic [7:0] data_i;
    logic [7:0] data_o;
    logic [7:0] to_host_data;
    logic [7:0] from_host_data;
    logic to_host_vld, to_host_rdy, from_host_vld, from_host_rdy;

    axis_ft245 
    #(
        .WR_SETUP_CYCLES(2),
        .WR_PULSE_CYCLES(3),
        .RD_PULSE_CYCLES(3),
        .RD_WAIT_CYCLES(2)
        // Safer/slower values:
        //.WR_SETUP_CYCLES(3),
        //.WR_PULSE_CYCLES(7),
        //.RD_PULSE_CYCLES(8),
        //.RD_WAIT_CYCLES(5)
    )
    ft245_inst
    (
        .clk(clk),
        .rst(reset),

        .ft245_d_in(data_i),
        .ft245_d_out(data_o),

        .ft245_rd_n(rd),
        .ft245_wr_n(wr),
        .ft245_rxf_n(rxf),
        .ft245_txe_n(txe),

        .ft245_d_oe(oe),
        .ft245_siwu_n(siwua),
        
        .input_axis_tdata(to_host_data),
        .input_axis_tvalid(to_host_vld),
        .input_axis_tready(to_host_rdy),

        .output_axis_tdata(from_host_data),
        .output_axis_tvalid(from_host_vld),
        .output_axis_tready(from_host_rdy)
    );

    // outgoing data
    assign d0 = (oe) ? data_o[0] : 'bz;
    assign d1 = (oe) ? data_o[1] : 'bz;
    assign d2 = (oe) ? data_o[2] : 'bz;
    assign d3 = (oe) ? data_o[3] : 'bz;
    assign d4 = (oe) ? data_o[4] : 'bz;
    assign d5 = (oe) ? data_o[5] : 'bz;
    assign d6 = (oe) ? data_o[6] : 'bz;
    assign d7 = (oe) ? data_o[7] : 'bz;

    // incoming data
    assign data_i[0] = d0;
    assign data_i[1] = d1;
    assign data_i[2] = d2;
    assign data_i[3] = d3;
    assign data_i[4] = d4;
    assign data_i[5] = d5;
    assign data_i[6] = d6;
    assign data_i[7] = d7;
    ///////
    
    logic [7:0] read_data;
    logic [7:0] write_data;
    logic read_rdy, read_vld, write_rdy, write_vld;
    
    axis_fifo 
    #(
        .DEPTH(1024), // was 512
        .LAST_ENABLE(0),
        .USER_ENABLE(0)
    ) 
    fifo_incoming
    (
        .clk(clk),
        .rst(reset),

        // INPUT
        .s_axis_tdata(from_host_data),
        .s_axis_tvalid(from_host_vld),
        .s_axis_tready(from_host_rdy),

        // OUTPUT
        .m_axis_tdata(read_data),
        .m_axis_tvalid(read_vld),
        .m_axis_tready(read_rdy)
    );

    axis_fifo 
    #(
        .DEPTH(1024), // was 512
        .LAST_ENABLE(0),
        .USER_ENABLE(0)
    ) 
    fifo_outgoing
    (
        .clk(clk),
        .rst(reset),

        // INPUT
        .s_axis_tdata(write_data),
        .s_axis_tvalid(write_vld),
        .s_axis_tready(write_rdy),

        // OUTPUT
        .m_axis_tdata(to_host_data),
        .m_axis_tvalid(to_host_vld),
        .m_axis_tready(to_host_rdy)
    );

    ///////

    //// LEDs ////

    assign led1 = ~read_rdy;
    assign led2 = ~read_vld;
    assign led3 = ~write_vld;

    ucaspian ucaspian_inst(
        .sys_clk(clk),
        .reset(reset),

        .read_data(read_data),
        .read_vld(read_vld),
        .read_rdy(read_rdy),

        .write_data(write_data),
        .write_vld(write_vld),
        .write_rdy(write_rdy),

        .led_0(),
        .led_1(),
        .led_2()
    );

endmodule
