/* uCaspian
 * Parker Mitchell, 2020
 *
 * Build Tools: Xilinx Vivado
 * Board: Numato Mimas A7 rev2
 * FPGA: Xilinx Artix7 50T (XC7A50T-1FGG484C)
 * Comm Interface: FTDI 2232H USB Bridge
 */
`include "ucaspian.sv"
`include "util.sv"
`include "axi_stream/axis_ft245.sv"
`include "axi_stream/axis_fifo.v"

module top(
    input  clk1, 

    /* bidirectional, asynchronous data bus */
    inout  data[7:0],

    /* comm flags */
    input  txe_n,
    input  rxf_n,
    output rd_n,
    output wr_n,
    output oe_n,
    output siwua,

    output led[7:0]
);

    // system clock
    logic clk;
    assign clk = clk1;

    // system reset
    logic [2:0] reset_cnt;
    logic reset;
    initial reset = 1;
    initial reset_cnt = 3'b111;

    always_ff @(posedge clk) begin
        if(reset_cnt > 0) begin
            reset_cnt <= reset_cnt - 1;
            reset     <= 1;
        end
        else if(reset_cnt != 0) begin
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
        .WR_PULSE_CYCLES(5),
        .RD_PULSE_CYCLES(5),
        .RD_WAIT_CYCLES(3)
    )
    ft245_inst
    (
        .clk(clk),
        .rst(reset),

        .ft245_d_in(data_i),
        .ft245_d_out(data_o),

        .ft245_rd_n(rd_n),
        .ft245_wr_n(wr_n),
        .ft245_rxf_n(rxf_n),
        .ft245_txe_n(txe_n),

        .ft245_d_oe(oe_n),
        .ft245_siwu_n(siwua),
        
        .input_axis_tdata(to_host_data),
        .input_axis_tvalid(to_host_vld),
        .input_axis_tready(to_host_rdy),

        .output_axis_tdata(from_host_data),
        .output_axis_tvalid(from_host_vld),
        .output_axis_tready(from_host_rdy)
    );

    // outgoing data
    assign data[0] = (oe_n) ? data_o[0] : 'bz;
    assign data[1] = (oe_n) ? data_o[1] : 'bz;
    assign data[2] = (oe_n) ? data_o[2] : 'bz;
    assign data[3] = (oe_n) ? data_o[3] : 'bz;
    assign data[4] = (oe_n) ? data_o[4] : 'bz;
    assign data[5] = (oe_n) ? data_o[5] : 'bz;
    assign data[6] = (oe_n) ? data_o[6] : 'bz;
    assign data[7] = (oe_n) ? data_o[7] : 'bz;

    // incoming data
    assign data_i[0] = data[0];
    assign data_i[1] = data[1];
    assign data_i[2] = data[2];
    assign data_i[3] = data[3];
    assign data_i[4] = data[4];
    assign data_i[5] = data[5];
    assign data_i[6] = data[6];
    assign data_i[7] = data[7];
    ///////
    
    logic [7:0] read_data;
    logic [7:0] write_data;
    logic read_rdy, read_vld, write_rdy, write_vld;
    
    axis_fifo 
    #(
        .DEPTH(2048),
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
        .DEPTH(2048),
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

    assign led[0] = ~read_rdy;
    assign led[1] = ~read_vld;
    assign led[2] = ~write_vld;
    assign led[3] = 0;
    assign led[4] = 1;
    assign led[5] = 1;
    assign led[6] = 0;
    assign led[7] = 1;

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
