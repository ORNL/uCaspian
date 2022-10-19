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
    //assign clk = clk1;
    
    logic PWRDWN, clk_rst, locked;
    logic CLKFBIN, CLKFBOUT;
    assign CLKFBIN = CLKFBOUT;
    
   MMCME2_BASE #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F(19.875),     // Multiply value for all CLKOUT (2.000-64.000).
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD(10.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT1_DIVIDE(1.0),
      .CLKOUT2_DIVIDE(1),
      .CLKOUT3_DIVIDE(1),
      .CLKOUT4_DIVIDE(1),
      .CLKOUT5_DIVIDE(1),
      .CLKOUT6_DIVIDE(1),
      .CLKOUT0_DIVIDE_F(6.625),    // Divide amount for CLKOUT0 (1.000-128.000).
      // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT6_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .CLKOUT6_PHASE(0.0),
      .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .DIVCLK_DIVIDE(2),         // Master division value (1-106)
      .REF_JITTER1(0.010),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   MMCME2_BASE_inst (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk),     // 1-bit output: CLKOUT0
      .CLKOUT0B(),   // 1-bit output: Inverted CLKOUT0
      .CLKOUT1(),     // 1-bit output: CLKOUT1
      .CLKOUT1B(),   // 1-bit output: Inverted CLKOUT1
      .CLKOUT2(),     // 1-bit output: CLKOUT2
      .CLKOUT2B(),   // 1-bit output: Inverted CLKOUT2
      .CLKOUT3(),     // 1-bit output: CLKOUT3
      .CLKOUT3B(),   // 1-bit output: Inverted CLKOUT3
      .CLKOUT4(),     // 1-bit output: CLKOUT4
      .CLKOUT5(),     // 1-bit output: CLKOUT5
      .CLKOUT6(),     // 1-bit output: CLKOUT6
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(CLKFBOUT),   // 1-bit output: Feedback clock
      .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
      // Status Ports: 1-bit (each) output: MMCM status ports
      .LOCKED(locked),       // 1-bit output: LOCK
      // Clock Inputs: 1-bit (each) input: Clock input
      .CLKIN1(clk1),       // 1-bit input: Clock
      // Control Ports: 1-bit (each) input: MMCM control ports
      .PWRDWN(PWRDWN),       // 1-bit input: Power-down
      .RST(clk_rst),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(CLKFBIN)      // 1-bit input: Feedback clock
   );
   


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
        .WR_SETUP_CYCLES(5),
        .WR_PULSE_CYCLES(10),
        .RD_PULSE_CYCLES(11),
        .RD_WAIT_CYCLES(6)
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
    //assign led[7] = 1;
    
    logic [25:0] ll_cnt;
    always_ff @(posedge clk) begin
        if(reset) begin
            ll_cnt <= 0;
        end
        else begin
            ll_cnt <= ll_cnt + 1;
        end
    end
    
    assign led[7] = ll_cnt[25];

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
