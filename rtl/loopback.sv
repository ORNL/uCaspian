/* uCaspian UART Loopback Test
 * Parker Mitchell, 2019
 *
 * Build tools: Project Icestorm + Yosys + ArachnePnR
 * Board: Gnarly Grey Upduino v2
 * FPGA: Lattice ice40up5k
 * Comm Interface: FTDI 232H USB to UART Bridge @ 2MBaud 
 */

`include "util.sv"

module top(
    input  serial_rxd,
    output serial_txd,
    output spi_cs,
    output led_r,
    output led_g,
    output led_b
);


    // system reset
    logic reset;
    logic [3:0] rst_cnt;

    initial reset = 1;
    initial rst_cnt = 4'b0000;

    always @(posedge clk_24) begin
        if(!reset) begin
            rst_cnt <= 0;
        end
        else if(rst_cnt == 4'b1111) begin
            reset   <= 0;
        end
        else begin
            rst_cnt <= rst_cnt + 1;
            reset   <= 1;
        end
    end

    // This is required to turn off the SPI flash chip
    // We are driving the same pins as SPI with our FTDI UART
    assign spi_cs = 1;

    // High frequnecy oscillator within FPGA
    wire clk_24;
    SB_HFOSC 
    #(
        // Default is 48MHz. Divide by 2 to get the desired 24MHz.
        .CLKHF_DIV("0b01")
    )
    u_hfosc (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(clk_24)
    );

    // UART at 2 MBaud
    wire clk_tx, clk_rx;
    divide_by_n #(.N(12)) cdiv_tx(clk_24, reset, clk_tx);
    divide_by_n #(.N(3)) cdiv_rx(clk_24, reset, clk_rx);

    // UART TX combined with a FIFO
    logic [7:0] uart_tx_data;
    logic uart_write_enable;
    logic tx_fifo_full;
    logic tx_fifo_empty;

    uart_tx_fifo transmit(
        .clk(clk_24),
        .reset(reset),
        .baud_x1(clk_tx),
        .write_enable(uart_write_enable),
        .data(uart_tx_data),
        .fifo_full(tx_fifo_full),
        .fifo_empty(tx_fifo_empty),
        .serial(serial_txd)
    );

    // UART RX combined with a FIFO
    logic [7:0] uart_rx_data;
    logic uart_read_enable;
    logic rx_fifo_full;
    logic rx_fifo_empty;

    uart_rx_fifo receive(
        .clk(clk_24),
        .reset(reset),
        .baud_x4(clk_rx),
        .read_enable(uart_read_enable),
        .data(uart_rx_data),
        .fifo_full(rx_fifo_full),
        .fifo_empty(rx_fifo_empty),
        .serial(serial_rxd)
    );

    // loopback flags
    //assign uart_tx_data         = uart_rx_data;
    //assign uart_read_enable     = !rx_fifo_empty;
    //assign uart_write_enable    = uart_read_enable;

    logic data_waiting; 

    always_ff @(posedge clk_24) begin
        uart_read_enable  <= 0;
        uart_write_enable <= 0;

        if(reset) begin
            uart_tx_data      <= 0;
            data_waiting      <= 0;
        end
        else if(ucnt == 1 && !rx_fifo_empty) begin
            uart_read_enable  <= 1;  
        end
        else if(ucnt == 2 && uart_read_enable) begin
            uart_read_enable  <= 0;
            uart_tx_data      <= uart_rx_data;
            data_waiting      <= 1;
        end
        else if(ucnt == 3 && data_waiting && !tx_fifo_full) begin
            uart_write_enable <= 1;
            data_waiting      <= 0;
        end
    end

    logic [1:0] ucnt;
    always_ff @(posedge clk_24) begin
        if(reset) ucnt <= 0;
        else ucnt <= ucnt + 1;
    end

    // PWM LED drivers for brightness control
    wire pwm_r, pwm_g, pwm_b;
    pwm pwm_g_driver(clk_24, 1, pwm_g);
    pwm pwm_r_driver(clk_24, 1, pwm_r);
    pwm pwm_b_driver(clk_24, 1, pwm_b);

    // heartbeat -> green LED
    logic [24:0] counter;
    always_ff @(posedge clk_24) counter <= counter + 1;
    assign led_g = !(counter[24] == 0 && counter[23] == 1 && pwm_g);

    // fifo full -> red LED
    wire full_pulse;
    pulse_stretcher red_led_pulse(clk_24, reset, rx_fifo_full, full_pulse);
    assign led_r = !(full_pulse && pwm_r);

    // fifo is not empty -> blue LED
    wire empty_pulse;
    wire rx_fifo_not_empty = !rx_fifo_empty;
    pulse_stretcher blue_led_pulse(clk_24, reset, rx_fifo_not_empty, empty_pulse);
    assign led_b = !(empty_pulse && pwm_b);

endmodule
