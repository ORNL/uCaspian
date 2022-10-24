/* uCaspian for Lattice ice40
 * Parker Mitchell, 2019
 *
 * Build Tools: Project Icestorm + Yosys + NextPnR
 * Board: Gnarly Grey Upduino v2
 * FPGA: Lattice ice40up5k
 * Comm Interface: FTDI 232H USB Bridge
 */

module top(
   // inout  gpio_37, // D0
   // inout  gpio_31, // D1
   // inout  gpio_35, // D2
   // inout  gpio_32, // D3
   // inout  gpio_27, // D4
   // inout  gpio_26, // D5
   // inout  gpio_25, // D6
   // inout  gpio_23, // D7

   // input  gpio_13, // C0 RXF#
   // input  gpio_19, // C1 TXE#
   // output gpio_18, // C2 RD#
   // output gpio_11, // C3 WR#

   output led_r,
   output led_g,
   output led_b,

   input serial_rxd,
   output spi_cs,
   output serial_txd
);
   assign spi_cs = 1; // it is necessary to turn off the SPI flash chip

   //// System reset ////

   logic reset;
   initial reset = 1;
   /* always_ff @(posedge clk_48) reset <= 0; */

   logic [31:0] counter;
   initial counter = 0;
   always_ff @(posedge clk_sys) begin
      if (counter[26]) begin
         reset <= 0;
      end
      counter <= counter + 1;
   end

   //// Clocks ////

   /* logic clk_48;  // Generated Clock */
   logic clk_sys; // System Clock
   logic clk_1;   // 3 Mbaud serial clock
   logic clk_4;   // 12 Mbaud serial clock

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
      .CLKHF(clk_sys)
   );

   // Generate a 3 MHz/12 MHz serial clock from the 24 MHz clock
   // This is the 3 Mb/s maximum supported by the FTDI chip
   divide_by_n #(.N(8)) div1(clk_sys, reset, clk_1);
   divide_by_n #(.N(2)) div4(clk_sys, reset, clk_4);

   // This generates the system clock at 24 MHz.
   /* divide_by_n #(.N( 2)) divclk(clk_48, reset, clk_sys); */

   //// UART to AXIS ////

   logic [7:0] read_data;
   logic read_rdy, read_vld;
   logic read_fifo_enable;
   logic read_fifo_empty;
   logic read_fifo_full;

   logic [7:0] write_data;
   logic write_rdy, write_vld;
   logic write_fifo_enable;
   logic write_fifo_full;

   uart_tx_fifo
   #(
      .FIFO_DEPTH(1024)
   )
   uart_fifo_outgoing
   (
      .clk(clk_sys),
      .reset(reset),
      .baud_x1(clk_1),
      .data(write_data),
      .write_enable(write_fifo_enable),
      .rts(1'b0),
      .fifo_full(write_fifo_full),
      .fifo_empty(),
      .fifo_almost_full(),
      .serial(serial_txd)
   );
   always_comb write_fifo_enable = write_rdy & write_vld;
   always_comb write_rdy = ~write_fifo_full;

   uart_rx_fifo
   #(
      .FIFO_DEPTH(1024)
   )
   uart_fifo_incoming
   (
      .clk(clk_sys),
      .reset(reset),
      .baud_x4(clk_4),
      .read_enable(read_fifo_enable),
      .data(read_data),
      .fifo_full(read_fifo_full),
      .fifo_empty(read_fifo_empty),
      .cts(),
      .serial(serial_rxd)
   );
   always_comb read_fifo_enable = read_rdy & read_vld;
   always_comb read_vld = ~read_fifo_empty;

   // Full Error Check
   logic full_err;
   initial full_err = 0;
   always_ff @(posedge clk_sys or posedge reset)
      if (reset)
         full_err <= 0;
      else begin
         if (read_fifo_full)
            full_err <= 1'b1;
      end

   //// uCaspian ////

   ucaspian ucaspian_inst(
       .sys_clk(clk_sys),
       .reset(reset),

       .read_data(read_data),
       .read_vld(read_vld),
       .read_rdy(read_rdy),

       .write_data(write_data),
       .write_vld(write_vld),
       .write_rdy(write_rdy),

       .led_0(),
       .led_1(),
       .led_2(),
       .led_3(led_3)
   );

   /* always_comb write_data = read_data; */
   /* always_comb write_vld = read_vld; */
   /* always_comb read_rdy = write_rdy; */

   //// LEDs ////
   logic led_0, led_1, led_2, led_3;

   always_comb led_0 = full_err; // Red LED
   always_comb led_1 = write_fifo_enable; // Green LED
   always_comb led_2 = read_fifo_enable; // Blue LED

   wire pwm_led, r_pulse, g_pulse, b_pulse;
   pwm pwm_driver(clk_sys, 1, pwm_led);

   pulse_stretcher #(.BITS(24)) red_led_pulse(clk_sys, reset, led_0, r_pulse);
   pulse_stretcher #(.BITS(24)) green_led_pulse(clk_sys, reset, led_1, g_pulse);
   pulse_stretcher #(.BITS(24)) blue_led_pulse(clk_sys, reset, led_2, b_pulse);

   assign led_r = !( (r_pulse && pwm_led) || reset);
   assign led_g = !(g_pulse && pwm_led);
   assign led_b = !(b_pulse && pwm_led);

endmodule
