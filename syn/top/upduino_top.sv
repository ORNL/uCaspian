/* uCaspian for Lattice ice40
 * Parker Mitchell, 2019
 *
 * Build Tools: Project Icestorm + Yosys + NextPnR
 * Board: Gnarly Grey Upduino v2
 * FPGA: Lattice ice40up5k
 * Comm Interface: FTDI 232H USB Bridge
 */

module top(
    inout  gpio_37, // D0
    inout  gpio_31, // D1
    inout  gpio_35, // D2
    inout  gpio_32, // D3
    inout  gpio_27, // D4
    inout  gpio_26, // D5
    inout  gpio_25, // D6
    inout  gpio_23, // D7

    input  gpio_13, // C0 RXF#
    input  gpio_19, // C1 TXE#
    output gpio_18, // C2 RD#
    output gpio_11, // C3 WR#

    output led_r,
    output led_g,
    output led_b
);
    // system reset
    logic reset;
    initial reset = 1;
    always_ff @(posedge sys_clk) reset <= 0;

    // system clock
    wire sys_clk;

    // High frequency oscillator within FPGA
    SB_HFOSC
    #(
        // Default is 48MHz. Divide by 4 to get the desired 24MHz.
        // 2'b00 = 48 MHz, 2'b01 = 24 MHz, 2'b10 = 12 MHz, 2'b11 = 6 MHz
        .CLKHF_DIV("0b01")
    )
    u_hfosc (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(sys_clk)
    );

    //// FTDI Async FIFO ////

    logic [7:0] data_i;
    logic [7:0] data_o;
    logic [7:0] to_host_data;
    logic [7:0] from_host_data;
    logic to_host_vld, to_host_rdy, from_host_vld, from_host_rdy;

    axis_ft245 
    #(
        .WR_SETUP_CYCLES(3),
        .WR_PULSE_CYCLES(3),
        .RD_PULSE_CYCLES(3),
        .RD_WAIT_CYCLES(3)
    )
    ft245_inst
    (
        .clk(sys_clk),
        .rst(reset),

        .ft245_d_in(data_i),
        .ft245_d_out(data_o),

        .ft245_rd_n(gpio_18),
        .ft245_wr_n(gpio_11),
        .ft245_rxf_n(gpio_13),
        .ft245_txe_n(gpio_19),

        .ft245_d_oe(oe),
        .ft245_siwu_n(),
        
        .input_axis_tdata(to_host_data),
        .input_axis_tvalid(to_host_vld),
        .input_axis_tready(to_host_rdy),

        .output_axis_tdata(from_host_data),
        .output_axis_tvalid(from_host_vld),
        .output_axis_tready(from_host_rdy)
    );

    // outgoing data
    assign gpio_37 = (oe) ? data_o[0] : 'bz;
    assign gpio_31 = (oe) ? data_o[1] : 'bz;
    assign gpio_35 = (oe) ? data_o[2] : 'bz;
    assign gpio_32 = (oe) ? data_o[3] : 'bz;
    assign gpio_27 = (oe) ? data_o[4] : 'bz;
    assign gpio_26 = (oe) ? data_o[5] : 'bz;
    assign gpio_25 = (oe) ? data_o[6] : 'bz;
    assign gpio_23 = (oe) ? data_o[7] : 'bz;

    // incoming data
    assign data_i[0] = gpio_37; // D0
    assign data_i[1] = gpio_31; // D1
    assign data_i[2] = gpio_35; // D2
    assign data_i[3] = gpio_32; // D3
    assign data_i[4] = gpio_27; // D4
    assign data_i[5] = gpio_26; // D5
    assign data_i[6] = gpio_25; // D6
    assign data_i[7] = gpio_23; // D7

    ///////
    
    logic [7:0] read_data;
    logic [7:0] write_data;
    logic read_rdy, read_vld, write_rdy, write_vld;
    
    axis_fifo 
    #(
        .DEPTH(1024),
        .LAST_ENABLE(0),
        .USER_ENABLE(0)
    ) 
    fifo_incoming
    (
        .clk(sys_clk),
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
        .clk(sys_clk),
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

    wire led_0, led_1, led_2;

    always_comb led_0 = read_rdy;
    always_comb led_1 = read_vld;
    always_comb led_2 = write_vld;

    wire pwm_led, r_pulse, g_pulse, b_pulse;
    pwm pwm_driver(sys_clk, 1, pwm_led);

    pulse_stretcher #(.BITS(24)) red_led_pulse(sys_clk, reset, led_0, r_pulse);
    pulse_stretcher #(.BITS(24)) green_led_pulse(sys_clk, reset, led_1, g_pulse);
    pulse_stretcher #(.BITS(24)) blue_led_pulse(sys_clk, reset, led_2, b_pulse);

    assign led_r = !(r_pulse && pwm_led);
    assign led_g = !(g_pulse && pwm_led);
    assign led_b = !(b_pulse && pwm_led);

    ucaspian ucaspian_inst(
        .sys_clk(sys_clk),
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
