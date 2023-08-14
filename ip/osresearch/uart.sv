 /*
  * uart.v - High-speed serial support. Includes a baud generator, UART,
  *            and a simple RFC1662-inspired packet framing protocol.
  *
  *            This module is designed a 3 Mbaud serial port.
  *            This is the highest data rate supported by
  *            the popular FT232 USB-to-serial chip.
  *
  * Copyright (C) 2009 Micah Dowty
  *           (C) 2018 Trammell Hudson
  *
  * Permission is hereby granted, free of charge, to any person obtaining a copy
  * of this software and associated documentation files (the "Software"), to deal
  * in the Software without restriction, including without limitation the rights
  * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  * copies of the Software, and to permit persons to whom the Software is
  * furnished to do so, subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall be included in
  * all copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  * THE SOFTWARE.
  */


/*
 * Byte transmitter, RS-232 8-N-1
 *
 * Transmits on 'serial'. When 'ready' goes high, we can accept another byte.
 * It should be supplied on 'data' with a pulse on 'data_strobe'.
 */

`include "util.vh"

module uart_tx(
    input               mclk,
    input               reset,
    input               baud_x1,
    input               rts,
    output logic        serial,
    output logic        ready,
    input        [7:0]  data,
    input               data_strobe
);

/*
 * Left-to-right shift register.
 * Loaded with data, start bit, and stop bit.
 *
 * The stop bit doubles as a flag to tell us whether data has been
 * loaded; we initialize the whole shift register to zero on reset,
 * and when the register goes zero again, it's ready for more data.
 */
logic [7+1+1:0] shiftreg;

/*
 * Serial output register. This is like an extension of the
 * shift register, but we never load it separately. This gives
 * us one bit period of latency to prepare the next byte.
 *
 * This register is inverted, so we can give it a reset value
 * of zero and still keep the 'serial' output high when idle.
 */
logic  serial_r;
always_comb serial = !serial_r;

/*
 * State machine
 */

always @(posedge mclk) begin
    if (reset) begin
        shiftreg <= 0;
        serial_r <= 0;
        ready    <= 0;
    end
    else if (data_strobe) begin
        shiftreg <= {
    	1'b1, // stop bit
    	data,
    	1'b0  // start bit (inverted)
        };
        ready <= 0;
    end
    else if (baud_x1) begin
        if (shiftreg == 0) begin
            /* Idle state is idle high, serial_r is inverted */
            serial_r <= 0;
            //ready <= 1;
            ready    <= !rts;
        end
        else begin
            serial_r <= !shiftreg[0];
        end

        // shift the output register down
        shiftreg <= {1'b0, shiftreg[7+1+1:1]};
    end
    else begin
        // rts is active low
	ready   <= (shiftreg == 0 && !rts);
    end
end

endmodule


/*
 * Byte receiver, RS-232 8-N-1
 *
 * Receives on 'serial'. When a properly framed byte is
 * received, 'data_strobe' pulses while the byte is on 'data'.
 *
 * Error bytes are ignored.
 */

module uart_rx(
    input               mclk,
    input               reset,
    input               baud_x4,
    input               serial,
    output logic [7:0]  data,
    output logic        data_strobe
);

/*
 * Synchronize the serial input to this clock domain
 */
wire         serial_sync;
d_flipflop_pair input_dff(mclk, reset, serial, serial_sync);

/*
 * State machine: Four clocks per bit, 10 total bits.
 */
logic [8:0]  shiftreg;
logic [5:0]  state;
/* logic        data_strobe; */
wire  [3:0]  bit_count = state[5:2];
wire  [1:0]  bit_phase = state[1:0];

wire         sampling_phase = (bit_phase == 1);
wire         start_bit = (bit_count == 0 && sampling_phase);
wire         stop_bit = (bit_count == 9 && sampling_phase);

wire         waiting_for_start = (state == 0 && serial_sync == 1);

wire         error = ( (start_bit && serial_sync == 1) ||
                       (stop_bit && serial_sync == 0) );

always_comb  data = shiftreg[7:0];

always @(posedge mclk or posedge reset) begin
    if (reset) begin
        state <= 0;
        data_strobe <= 0;
    end
    else if (baud_x4) begin
        if (waiting_for_start || error || stop_bit) begin
            state <= 0;
        end
        else begin
            state <= state + 1;
        end

        if (bit_phase == 1) begin
            shiftreg <= { serial_sync, shiftreg[8:1] };
        end

        data_strobe <= stop_bit && !error;

    end
    else begin
        data_strobe <= 0;
    end
end

endmodule


/*
 * Output UART with a block RAM FIFO queue.
 *
 * Add bytes to the queue and they will be printed when the line is idle.
 */
module uart_tx_fifo(
    input           clk,
    input           reset,
    input           baud_x1,
    input  [7:0]    data,
    input           write_enable,
    input           rts,
    output logic    fifo_full,
    output logic    fifo_empty,
    output logic    fifo_almost_full,
    output logic    serial
);

parameter FIFO_DEPTH = 512;

wire  uart_txd_ready; // high the UART is ready to take a new byte
logic uart_txd_strobe; // pulse when we have a new byte to transmit
logic [7:0] uart_txd;

uart_tx txd(
    .mclk(clk),
    .reset(reset),
    .baud_x1(baud_x1),
    .serial(serial),
    .rts(rts),
    .ready(uart_txd_ready),
    .data(uart_txd),
    .data_strobe(uart_txd_strobe)
);

logic fifo_read_enable;

fifo #(.DEPTH(FIFO_DEPTH), .WIDTH(8)) buffer(
    .clk(clk),
    .reset(reset),
    .write_data(data),
    .write_enable(write_enable),
    .read_enable(fifo_read_enable),
    .read_data(uart_txd),
    .full(fifo_full),
    .almost_full(fifo_almost_full),
    .empty(fifo_empty)
);

// drain the fifo into the serial port
always @(posedge clk) begin
    fifo_read_enable <= 0;
    uart_txd_strobe <= 0;

    if (!fifo_empty
    &&  uart_txd_ready
    && !rts
    && !write_enable // avoid dual port RAM if possible
    && !uart_txd_strobe // don't TX twice on one byte
    ) begin
        fifo_read_enable <= 1;
        uart_txd_strobe <= 1;
    end
end

endmodule

module uart_rx_fifo(
    input              clk,
    input              reset,
    input              baud_x4,
    input              read_enable,
    output logic [7:0] data,
    output logic       fifo_full,
    output logic       fifo_empty,
    output logic       cts,
    input              serial
);

parameter FIFO_DEPTH = 512;

wire [7:0] rx_data;
wire rx_read;

uart_rx rxd(
    .mclk(clk),
    .reset(reset),
    .baud_x4(baud_x4),
    .serial(serial),
    .data(rx_data),
    .data_strobe(rx_read)
);

wire [7:0] read_data;
wire fifo_almost_full;

// cts is active low
always_ff @(posedge clk)
    cts <= fifo_almost_full;

fifo #(.DEPTH(FIFO_DEPTH), .WIDTH(8)) buffer(
    .clk(clk),
    .reset(reset),
    .write_data(rx_data),
    .write_enable(rx_read),
    .read_enable(read_enable),
    .read_data(read_data),
    .full(fifo_full),
    .almost_full(fifo_almost_full),
    .empty(fifo_empty)
);

always_comb data = read_data;

endmodule
