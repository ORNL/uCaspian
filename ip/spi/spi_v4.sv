module SPI_slave_v4(
  // Base signals
  input  clk,
  input  reset,
  output logic LED,
  output logic LED1,
  output logic LED2,
  output logic LED3,
  output spi_reset, // SPI was sent a reset command.
  // SPI
  input  SCK,
  input  MOSI,
  output MISO,
  input  SSEL,
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

localparam WIDTH_BITS = $clog2(WIDTH);
localparam DEPTH_BITS = $clog2(DEPTH);

// Default spi_reset to 0
initial spi_reset = 0;
logic reset_n = ~reset;

/* Recieve SPI Data */
logic SSEL_active = ~SSEL;
logic SSEL_previous;
logic SSEL_startmessage = (SSEL_previous == 1 && SSEL == 0);  // message starts at falling edge
logic SSEL_endmessage = (SSEL_previous == 0 && SSEL == 1);  // message stops at rising edge

always_ff @(posedge SCK) SSEL_previous <= SSEL;

// Bit counter to count the bits as they come in
logic [WIDTH_BITS-1:0] bitcnt;

logic byte_received;  // high when a byte has been received
logic [WIDTH-1:0] byte_data_received;
logic [WIDTH-1:0] byte_data_received_l;

// // we use the LSB of the data received to control an LED
// logic LED;
// always_ff @(posedge clk) if(byte_received) LED <= byte_data_received[0];
// always_comb LED <= (read_rdy & read_vld) | (write_rdy & write_vld) | write_fifo_full;
assign LED1 = write_fifo_write_enable;
assign LED2 = read_fifo_read_enable;
assign LED3 = read_fifo_empty;

/* Transmit SPI Data */

logic [WIDTH-1:0] byte_data_to_send;
logic [WIDTH-1:0] byte_data_sent;

always_ff @(negedge SCK) begin
    MISO <= byte_data_sent[WIDTH-1];  // send MSB first
end

always_ff @(negedge SCK) begin
  if ((parser_state == PARSER_WRITE || parser_state == PARSER_WRITE_READ) && (bitcnt==WIDTH-1)) begin
    write_fifo_write_enable = 1'b1;
  end
  else begin
    write_fifo_write_enable = 1'b0;
  end
end

// assign MISO = byte_data_sent[WIDTH-1];  // send MSB first
// we assume that there is only one slave on the SPI bus
// so we don't bother with a tri-state buffer for MISO
// otherwise we would need to tri-state MISO when SSEL is inactive

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

always_ff @(posedge SCK, posedge SSEL) begin
  spi_reset <= 1'b0;

  // write_fifo_write_enable = 1'b0;
  read_fifo_read_enable <= 1'b0;

  if(SSEL) begin
    parser_state <= PARSER_IDLE;
    byte_data_to_send <= 0;
    byte_data_sent <= 0;  
    bitcnt <= 0;
  end

  else begin // SSEL_active
    LED <= 0;
    bitcnt <= bitcnt + 1;
    byte_data_received = {byte_data_received[WIDTH-2:0], MOSI};
    byte_data_received_l <= {byte_data_received[WIDTH-2:0], MOSI};
    byte_received = SSEL_active && (bitcnt==WIDTH-1);
    // byte_data_sent <= byte_data_to_send;  
    byte_data_sent <= {byte_data_sent[WIDTH-2:0], 1'b0};
    if (byte_received) begin
      bit_count <= 1;
      unique case(parser_state)

      PARSER_IDLE: begin
        unique case(byte_data_received)

          OP_READ_STATUS: begin
            parser_state <= PARSER_STATUS_AVAIL;
            byte_data_sent <= write_fifo_avail;
          end

          OP_READ_BYTES: begin
            parser_state <= PARSER_READ;
            byte_data_sent <= read_fifo_read_data;
          end

          OP_WRITE_BYTES: begin
            parser_state <= PARSER_WRITE;
            LED <= 1;
          end

          OP_WRITE_READ_BYTES: begin
            parser_state <= PARSER_WRITE_READ;
            byte_data_sent <= read_fifo_read_data;
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
        byte_data_sent <= read_fifo_count;
      end 

      PARSER_READ: begin
        byte_data_sent <= read_fifo_read_data;
      end 

      PARSER_WRITE: begin
        // write_fifo_write_data = byte_data_received;
        // write_fifo_write_enable = 1'b1;
      end 

      PARSER_WRITE_READ: begin
        byte_data_sent <= read_fifo_read_data;

        // write_fifo_write_data = byte_data_received;
        // write_fifo_write_enable = 1'b1;
      end
      
      default: begin
        parser_state <= PARSER_IDLE;
      end
      endcase
    end

    if(bitcnt==2) begin
      if (parser_state == PARSER_READ || parser_state == PARSER_WRITE_READ) begin
        read_fifo_read_enable <= 1'b1;
      end
    end
  end
end

always_comb  write_fifo_write_data <= {byte_data_received_l[WIDTH-1:1], MOSI};

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
async_fifo1 #(.DSIZE(WIDTH), .ASIZE(DEPTH_BITS)) write_fifo (
  .winc(write_fifo_write_enable), 
  .wclk(SCK), 
  .wrst_n(reset_n),
  .rinc(write_fifo_read_enable), 
  .rclk(clk), 
  .rrst_n(reset_n),
  .wdata(write_fifo_write_data),
  // .wdata(8'b10000001),

  .rdata(write_fifo_read_data),
  .wfull(write_fifo_full),
  .rempty(write_fifo_empty),
  .count(write_fifo_count),
  .avail(write_fifo_avail)
);
// fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) write_fifo(
//   .clk(SCK),
//   .reset(reset),
//   .write_data(write_fifo_write_data),
//   .write_enable(write_fifo_write_enable),
//   .read_enable(write_fifo_read_enable),
//   .read_data(write_fifo_read_data),
//   .full(write_fifo_full),
//   .almost_full(write_fifo_almost_full),
//   .empty(write_fifo_empty),
//   .count(write_fifo_count),
//   .avail(write_fifo_avail),
// );

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
async_fifo1 #(.DSIZE(WIDTH), .ASIZE(DEPTH_BITS)) read_fifo (
  .winc(read_fifo_write_enable), 
  .wclk(clk), 
  .wrst_n(reset_n),
  .rinc(read_fifo_read_enable), 
  .rclk(SCK), 
  .rrst_n(reset_n),
  .wdata(read_fifo_write_data),

  .rdata(read_fifo_read_data),
  .wfull(read_fifo_full),
  .rempty(read_fifo_empty),
  .count(read_fifo_count),
  .avail(read_fifo_avail)
);
// fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) read_fifo(
//   .clk(SCK),
//   .reset(reset),
//   .write_data(read_fifo_write_data),
//   .write_enable(read_fifo_write_enable),
//   .read_enable(read_fifo_read_enable),
//   .read_data(read_fifo_read_data),
//   .full(read_fifo_full),
//   .almost_full(read_fifo_almost_full),
//   .empty(read_fifo_empty),
//   .count(read_fifo_count),
//   .avail(read_fifo_avail),
// );

/* FIFO to AXI-Stream */
always_comb read_data <= write_fifo_read_data;
always_comb read_vld <= ~write_fifo_empty;
always_comb write_fifo_read_enable <= read_rdy & read_vld;

always_comb read_fifo_write_data <= write_data;
always_comb write_rdy <= ~read_fifo_full;
always_comb read_fifo_write_enable <= write_rdy & write_vld;

endmodule
