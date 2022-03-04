/*
 * Parts from: https://www.fpga4fun.com/SPI2.html
 */
`include "util.sv"

module SPI_slave(
  // Base signals
  input clk,
  input reset,
  output logic LED,
  // SPI
  input SCK,
  input MOSI,
  output MISO,
  input SSEL,
  // AXI-Stream
  output read_data,
  output read_vld,
  input  read_rdy,
  input  write_data,
  input  write_vld,
  output write_rdy
);

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
logic [7:0] byte_data_received;

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
always_comb LED <= write_fifo_full;

/* Transmit SPI Data */

logic [7:0] byte_data_sent;
logic [7:0] byte_data_to_send;

logic [7:0] cnt;
always_ff @(posedge clk) begin
   if(reset) begin
      cnt<=8'h0;
   end
   else if(SSEL_startmessage) begin
      cnt<=cnt+8'h1;  // count the messages
   end
end

always_ff @(posedge clk)
if(SSEL_active)
begin
  if(SSEL_startmessage)
    byte_data_sent <= 8'h00;
  else
  if(SCK_fallingedge)
  begin
    if(bitcnt==3'b000)
      byte_data_sent <= byte_data_to_send;  
    else
      byte_data_sent <= {byte_data_sent[6:0], 1'b0};
  end
end

assign MISO = byte_data_sent[7];  // send MSB first
// we assume that there is only one slave on the SPI bus
// so we don't bother with a tri-state buffer for MISO
// otherwise we would need to tri-state MISO when SSEL is inactive

/* Read FIFO */
logic read_fifo_write_data;
logic read_fifo_write_data;
logic read_fifo_write_enable;
logic read_fifo_read_enable;
logic read_fifo_read_data;
logic read_fifo_full;
logic read_fifo_almost_full;
logic read_fifo_empty;
logic [7:0] read_fifo_count;
logic [7:0] read_fifo_avail;
fifo #(.DEPTH(16), .WIDTH(8)) read_fifo(
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

/* Write FIFO */
logic write_fifo_write_data;
logic write_fifo_write_data;
logic write_fifo_write_enable;
logic write_fifo_read_enable;
logic write_fifo_read_data;
logic write_fifo_full;
logic write_fifo_almost_full;
logic write_fifo_empty;
logic [7:0] write_fifo_count;
logic [7:0] write_fifo_avail;
fifo #(.DEPTH(16), .WIDTH(8)) write_fifo(
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

/* Parser State Machine */
localparam [7:0]
  OP_READ_STATUS   = 8'b10000001,
  OP_READ_BYTES    = 8'b10000010,
  OP_WRITE_BYTES   = 8'b00000100;

localparam [2:0]
    PARSER_IDLE         = 0,
    PARSER_STATUS_AVAIL = 1,
    PARSER_WRITE        = 2;
logic [2:0]  parser_state;
initial parser_state = PARSER_IDLE;

always_ff @(posedge clk) begin

  write_fifo_write_data <= 8'h00;
  write_fifo_write_enable <= 1'b0;
  
  if(~SSEL_active) begin
    parser_state <= PARSER_IDLE;
    byte_data_to_send <= 8'h00;
  end
  else begin // SSEL_active
    if (byte_received) begin
      case(parser_state)
      PARSER_IDLE: begin
        case(byte_data_received)
          OP_READ_STATUS: begin
            parser_state <= PARSER_STATUS_AVAIL;
            byte_data_to_send <= write_fifo_avail;
          end
          OP_READ_BYTES: begin
          end
          OP_WRITE_BYTES: begin
            parser_state <= PARSER_WRITE;
          end
          default: begin
          end
        endcase
      end 
      PARSER_STATUS_AVAIL: begin
            parser_state <= PARSER_IDLE;
            byte_data_to_send <= read_fifo_count;
      end 
      PARSER_WRITE: begin
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