/* uCaspian for Lattice ice40
 * Parker Mitchell, 2019
 * Aaron Young, 2022
 *
 * Build Tools: Project Icestorm + Yosys + NextPnR
 * Board: Gnarly Grey Upduino v2
 * FPGA: Lattice ice40up5k
 * Comm Interface: FTDI 232H USB Bridge
 */

`include "ucaspian.sv"
`include "util.sv"
// `include "spi.sv"
// `include "spi_v2.sv"
// `include "spi_v3.sv"
`include "spi_v4.sv"
/* `include "axi_stream/axis_ft245.sv" */
/* `include "axi_stream/axis_fifo.v" */

module top(
   input  gpio_2,  // SCLK
   input  gpio_46, // MOSI
   output gpio_47, // MISO
   input  gpio_45, // SSEL
   // output  gpio_3, // System Clock Debug Output
   // output  gpio_32, // Debug Port 1
   // output  gpio_27, // Debug Port 2
   // output  gpio_26, // Debug Port 3
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

   // assign gpio_3 = clk_sys;

   //// System reset ////

   logic reset;
   initial reset = 1;
   /* always_ff @(posedge clk_48) reset <= 0; */

   logic [31:0] counter;
   initial counter = 0;
   // always_ff @(posedge clk_sys) begin
   always_ff @(posedge clk_sys) begin
      if (spi_reset) begin
         reset <= 1;
         counter <= 0;
      end
      if (counter[26]) begin
         reset <= 0;
      end
      counter <= counter + 1;
   end

   //// Clocks ////

   /* logic clk_48;  // Generated Clock */
   logic clk_sys; // 24 MHz System Clock
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

   //// SPI ////
   logic spi_led;
   logic spi_reset;
   logic [7:0] spi_read_data;
   logic spi_read_vld;
   logic spi_read_rdy;
   logic [7:0] spi_write_data;
   logic spi_write_vld;
   logic spi_write_rdy;
   // SPI_slave #(.DEPTH(128), .WIDTH(8)) SPI_slave_inst
   // SPI_slave_v2 #(.DEPTH(128), .WIDTH(8)) SPI_slave_inst
   SPI_slave_v4 #(.DEPTH(16), .WIDTH(8)) SPI_slave_inst
   (
      .clk(clk_sys),
      .reset(reset),
      .LED(spi_led),
      .LED1(),
      .LED2(),
      .LED3(),
      .spi_reset(spi_reset),

      .SCK(gpio_2),
      .MOSI(gpio_46),
      .MISO(gpio_47),
      .SSEL(gpio_45),

      .read_data(spi_read_data),
      .read_vld(spi_read_vld),
      .read_rdy(spi_read_rdy),
      .write_data(spi_write_data),
      .write_vld(spi_write_vld),
      .write_rdy(spi_write_rdy)
   );

   // SPI_slave_v3 #(.DEPTH(128), .WIDTH(8)) SPI_slave_inst
   // (
   //    .clk_logic(clk_1),
   //    .clk_comm(clk_sys),
   //    .reset(reset),
   //    .LED(spi_led),
   //    .spi_reset(spi_reset),

   //    .SCK(gpio_2),
   //    .MOSI(gpio_46),
   //    .MISO(gpio_47),
   //    .SSEL(gpio_45),

   //    .read_data(spi_read_data),
   //    .read_vld(spi_read_vld),
   //    .read_rdy(spi_read_rdy),
   //    .write_data(spi_write_data),
   //    .write_vld(spi_write_vld),
   //    .write_rdy(spi_write_rdy)
   // );

   //// uCaspian ////

   ucaspian ucaspian_inst(
       .sys_clk(clk_sys),
       .reset(reset),

       .read_data(spi_read_data),
       .read_vld(spi_read_vld),
       .read_rdy(spi_read_rdy),

       .write_data(spi_write_data),
       .write_vld(spi_write_vld),
       .write_rdy(spi_write_rdy),

       .led_0(),
       .led_1(),
       .led_2(),
       .led_3()
   );

   //// LEDs ////
   logic led_0, led_1, led_2, led_3;

   always_comb led_0 = spi_led; // Red LED
   always_comb led_1 = 1'b0; // Green LED
   always_comb led_2 = 1'b0; // Blue LED

   wire pwm_led, r_pulse, g_pulse, b_pulse;
   pwm pwm_driver(clk_sys, 1, pwm_led);

   pulse_stretcher #(.BITS(24)) red_led_pulse(clk_sys, reset, led_0, r_pulse);
   pulse_stretcher #(.BITS(24)) green_led_pulse(clk_sys, reset, led_1, g_pulse);
   pulse_stretcher #(.BITS(24)) blue_led_pulse(clk_sys, reset, led_2, b_pulse);

   // assign led_r = !(r_pulse && pwm_led);
   assign led_r = !(led_0);
   assign led_g = !(g_pulse && pwm_led);
   assign led_b = !(b_pulse && pwm_led);

endmodule
