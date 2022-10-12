/*
 * Parts from: https://www.fpga4fun.com/SPI2.html
 */
`include "util.sv"

module SPI_slave(
  // Base signals
  input clk,
  input reset,
  output logic LED,
  output spi_reset, // SPI was sent a reset command.
  // SPI
  input SCK,
  input MOSI,
  output MISO,
  input SSEL,
  // AXI-Stream
  output [WIDTH-1:0] read_data,
  output read_vld,
  input  read_rdy,
  input  [WIDTH-1:0] write_data,
  input  write_vld,
  output write_rdy
);
parameter WIDTH = 8;
parameter DEPTH = 16;

// Default spi_reset to 0
initial spi_reset = 0;

/* Sample/synchronize SPI signals */

// sync SCK to the FPGA clock using a 3-bits shift register
logic [2:0] SCKr; always_ff @(posedge clk) SCKr <= {SCKr[1:0], SCK};
logic SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
logic SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

// same thing for SSEL
logic [2:0] SSELr; always_ff @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
logic SSEL_active = ~SSELr[1];  // SSEL is active low
logic SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
logic SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

// and for MOSI
logic [1:0] MOSIr; always_ff @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
logic MOSI_data = MOSIr[1];

/* Recieve SPI Data */

// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
logic [2:0] bitcnt;

logic byte_received;  // high when a byte has been received
logic [WIDTH-1:0] byte_data_received;

always_ff @(posedge clk)
begin
  if(~SSEL_active)
    bitcnt <= 3'b000;
  else
  if(SCK_risingedge)
  begin
    bitcnt <= bitcnt + 3'b001;

    // implement a shift-left register (since we receive the data MSB first)
    byte_data_received <= {byte_data_received[6:0], MOSI_data};
  end
end

always_ff @(posedge clk) byte_received <= SSEL_active && SCK_risingedge && (bitcnt==3'b111);

// // we use the LSB of the data received to control an LED
// logic LED;
// always_ff @(posedge clk) if(byte_received) LED <= byte_data_received[0];
always_comb LED <= (read_rdy & read_vld) | (write_rdy & write_vld) | write_fifo_full;

/* Transmit SPI Data */

logic [WIDTH-1:0] byte_data_sent;
logic [WIDTH-1:0] byte_data_to_send;

logic [WIDTH-1:0] cnt;
always_ff @(posedge clk) begin
   if(reset) begin
      cnt<=WIDTH'h0;
   end
   else if(SSEL_startmessage) begin
      cnt<=cnt+WIDTH'h1;  // count the messages
   end
end

always_ff @(posedge clk) begin
  read_fifo_read_enable <= 1'b0;
  if(SSEL_active) begin
    if(SSEL_startmessage) begin
      byte_data_sent <= WIDTH'h00;
    end
    else
    if(SCK_fallingedge) begin
      if(bitcnt==3'b001) begin
        if (parser_state == PARSER_READ || parser_state == PARSER_WRITE_READ) begin
          read_fifo_read_enable <= 1'b1;
        end
      end
      if(bitcnt==3'b000) begin
        byte_data_sent <= byte_data_to_send;  
      end
      else begin
        byte_data_sent <= {byte_data_sent[6:0], 1'b0};
      end
    end
  end
end

assign MISO = byte_data_sent[WIDTH-1];  // send MSB first
// we assume that there is only one slave on the SPI bus
// so we don't bother with a tri-state buffer for MISO
// otherwise we would need to tri-state MISO when SSEL is inactive

/* Write FIFO */
logic [WIDTH-1:0] write_fifo_write_data;
logic write_fifo_write_enable;
logic write_fifo_read_enable;
logic [WIDTH-1:0] write_fifo_read_data;
logic write_fifo_full;
logic write_fifo_almost_full;
logic write_fifo_empty;
logic [7:0] write_fifo_count;
logic [7:0] write_fifo_avail;
fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) write_fifo(
  .clk(clk),
  .reset(reset),
  .write_data(write_fifo_write_data),
  .write_enable(write_fifo_write_enable),
  .read_enable(write_fifo_read_enable),
  .read_data(write_fifo_read_data),
  .full(write_fifo_full),
  .almost_full(write_fifo_almost_full),
  .empty(write_fifo_empty),
  .count(write_fifo_count),
  .avail(write_fifo_avail),
);

/* Read FIFO */
logic [WIDTH-1:0] read_fifo_write_data;
logic read_fifo_write_enable;
logic read_fifo_read_enable;
logic [WIDTH-1:0] read_fifo_read_data;
logic read_fifo_full;
logic read_fifo_almost_full;
logic read_fifo_empty;
logic [7:0] read_fifo_count;
logic [7:0] read_fifo_avail;
fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) read_fifo(
  .clk(clk),
  .reset(reset),
  .write_data(read_fifo_write_data),
  .write_enable(read_fifo_write_enable),
  .read_enable(read_fifo_read_enable),
  .read_data(read_fifo_read_data),
  .full(read_fifo_full),
  .almost_full(read_fifo_almost_full),
  .empty(read_fifo_empty),
  .count(read_fifo_count),
  .avail(read_fifo_avail),
);

/* FIFO to AXI-Stream */
always_comb read_data <= write_fifo_read_data;
always_comb read_vld  <= ~write_fifo_empty;
always_comb write_fifo_read_enable <= read_rdy & read_vld;

always_comb read_fifo_write_data <= write_data;
always_comb write_rdy <= ~read_fifo_full;
always_comb read_fifo_write_enable <= write_rdy & write_vld;

/* Parser State Machine */
localparam [WIDTH-1:0]
  OP_READ_STATUS      = WIDTH'b10000001,
  OP_READ_BYTES       = WIDTH'b10000010,
  OP_WRITE_BYTES      = WIDTH'b00000100,
  OP_WRITE_READ_BYTES = WIDTH'b10000110,
  OP_RESET            = WIDTH'b00001000;

typedef enum {
  PARSER_IDLE,
  PARSER_STATUS_AVAIL,
  PARSER_READ,
  PARSER_WRITE,
  PARSER_WRITE_READ
} parser_state_t;
parser_state_t parser_state;
initial parser_state = PARSER_IDLE;

always_ff @(posedge clk) begin
  spi_reset <= 1'b0;

  write_fifo_write_data <= WIDTH'h00;
  write_fifo_write_enable <= 1'b0;

  if(~SSEL_active) begin
    parser_state <= PARSER_IDLE;
    byte_data_to_send <= WIDTH'h00;
  end

  else begin // SSEL_active
    if (byte_received) begin
      unique case(parser_state)
      PARSER_IDLE: begin
        unique case(byte_data_received)

          OP_READ_STATUS: begin
            parser_state <= PARSER_STATUS_AVAIL;
            byte_data_to_send <= write_fifo_avail;
          end

          OP_READ_BYTES: begin
            parser_state <= PARSER_READ;
            byte_data_to_send <= read_fifo_read_data;
          end

          OP_WRITE_BYTES: begin
            parser_state <= PARSER_WRITE;
          end

          OP_WRITE_READ_BYTES: begin
            parser_state <= PARSER_WRITE_READ;
            byte_data_to_send <= read_fifo_read_data;
          end

          OP_RESET: begin
            spi_reset <= 1'b1;
          end

          default: begin
          end
        endcase
      end 

      PARSER_STATUS_AVAIL: begin
        parser_state <= PARSER_IDLE;
        byte_data_to_send <= read_fifo_count;
      end 

      PARSER_READ: begin
        byte_data_to_send <= read_fifo_read_data;
      end 

      PARSER_WRITE: begin
        write_fifo_write_data <= byte_data_received;
        write_fifo_write_enable <= 1'b1;
      end 

      PARSER_WRITE_READ: begin
        byte_data_to_send <= read_fifo_read_data;

        write_fifo_write_data <= byte_data_received;
        write_fifo_write_enable <= 1'b1;
      end
      
      default: begin
        parser_state <= PARSER_IDLE;
      end
      endcase
    end
  end
end

endmodule