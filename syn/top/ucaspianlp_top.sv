`default_nettype none

module top #(
  parameter bit INTERNAL_CLOCK = 1,
  parameter bit LOOPBACK_UART = 0,
  parameter bit HEARTBEAT_LED = 1
)(
  input  logic clk25,
  input  logic en,
  input  logic rxd,
  output logic txd,
  output logic irq,
  output logic spi_cs,
  output logic [3:0] led,
);
  localparam int unsigned PRESCALER = 24000000 / 1000000; // 1 Mbaud

  logic       sys_clk;
  logic       clk_hf;

  logic [7:0] wr_data;
  logic       wr_valid;
  logic       wr_ready;

  logic [7:0] rd_data;
  logic       rd_valid;
  logic       rd_ready;

  logic [7:0] tx_data;
  logic       tx_valid;
  logic       tx_ready;

  logic [7:0] rx_data;
  logic       rx_valid;
  logic       rx_ready;

  logic        reset = 1'b1;
  logic [26:0] count = '0;

  logic rxd_q1;
  logic rxd_q2;

  always_ff @(posedge sys_clk) begin
    {rxd_q2, rxd_q1} <= {rxd_q1, rxd};
  end

  always_ff @(posedge sys_clk or negedge en) begin
    if (!en) begin
      count <= '0;
    end else if (count == '1) begin
      reset <= 1'b0;
    end else begin
      count <= count + 1'b1;
    end
  end

  assign irq = 1'b0;

  // TODO Probably not required on ucaspian board
  assign spi_cs = 1'b1;

  logic heartbeat = 1'b0;

  if (HEARTBEAT_LED) begin
    logic [26:0] cycles = '0;

    always_ff @(posedge sys_clk) begin
      cycles <= cycles + 1'b1;
      if (cycles == '1) begin
        heartbeat <= ~heartbeat;
      end
    end
  end

  assign led = {~heartbeat, ~en, ~rd_valid, ~wr_valid};

  // 24 MHz
  if (INTERNAL_CLOCK) begin
    SB_HFOSC #(
    .CLKHF_DIV("0b01")
    ) hfosc_u (
      .CLKHFEN(en),
      .CLKHFPU(1'b1),
      .CLKHF  (clk_hf)
    );
    assign sys_clk = clk_hf;
  end else begin
    assign sys_clk = clk25;
  end

  if (LOOPBACK_UART) begin
    stream_fifo #(
    .DataWidth(8),
    .DataDepth(512)
    ) loop_fifo_u (
      .clock_i  (sys_clk),
      .reset_i  (reset),
      .s_valid_i(rx_valid),
      .s_ready_o(rx_ready),
      .s_data_i (rx_data),
      .m_valid_o(tx_valid),
      .m_ready_i(tx_ready),
      .m_data_o (tx_data)
    );
  end else begin
    stream_fifo #(
    .DataWidth(8),
    .DataDepth(512)
    ) tx_fifo_u (
      .clock_i  (sys_clk),
      .reset_i  (reset),
      .s_valid_i(wr_valid),
      .s_ready_o(wr_ready),
      .s_data_i (wr_data),
      .m_valid_o(tx_valid),
      .m_ready_i(tx_ready),
      .m_data_o (tx_data)
    );

    stream_fifo #(
    .DataWidth(8),
    .DataDepth(512)
    ) rx_fifo_u (
      .clock_i  (sys_clk),
      .reset_i  (reset),
      .s_valid_i(rx_valid),
      .s_ready_o(rx_ready),
      .s_data_i (rx_data),
      .m_valid_o(rd_valid),
      .m_ready_i(rd_ready),
      .m_data_o (rd_data)
    );
  end

  uart #(
  .PRESCALER(PRESCALER)
  ) uart_u (
    .clk(sys_clk),
    .reset,
    .rx (rxd_q2),
    .rx_ready,
    .rx_valid,
    .rx_data,
    .tx_data,
    .tx_valid,
    .tx_ready,
    .tx (txd)
  );

  ucaspian ucaspian_u (
    .sys_clk,
    .reset,
    .write_data(wr_data),
    .write_vld(wr_valid),
    .write_rdy(wr_ready),
    .read_data(rd_data),
    .read_vld(rd_valid),
    .read_rdy(rd_ready),
    .led_0(),
    .led_1(),
    .led_2(),
    .led_3()
  );

endmodule
