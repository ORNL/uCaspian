// Brett Witherspoon <witherspoocb@ornl.gov>

// Wishbone interface for ucaspian
module ucaspian_wb #(
    parameter  int FifoDepth = 32,
    parameter  int AdrWidth  = 30,
    parameter  int DatWidth  = 32,
    localparam int SelWidth  = DatWidth / 8,
    localparam int LedWidth  = 4,
    localparam bit [3:0] Version = 4'h1
) (
    input  logic                wb_clk_i,
    input  logic                wb_rst_i,
    input  logic [AdrWidth-1:0] wb_adr_i,
    input  logic [DatWidth-1:0] wb_dat_i,
    output logic [DatWidth-1:0] wb_dat_o,
    input  logic [SelWidth-1:0] wb_sel_i,
    input  logic                wb_we_i,
    input  logic                wb_stb_i,
    input  logic                wb_cyc_i,
    output logic                wb_ack_o,
    output logic [LedWidth-1:0] led_o
);
  logic [7:0] wr_data;
  logic       wr_valid;
  logic       wr_ready;

  logic [7:0] rd_data;
  logic       rd_valid;
  logic       rd_ready;

  logic [7:0] cmd_data;
  logic       cmd_valid;
  logic       cmd_ready;

  logic [7:0] rsp_data;
  logic       rsp_valid;
  logic       rsp_ready;

  logic [6:0] timer;
  wire timeout = timer == '1;

  assign cmd_data = wb_dat_i[7:0];

  wire unused = &{wb_sel_i, wb_dat_i[31:8], 1'b0};

  // Need a timeout for busses that do not support wb_err and wb_stall
  always_ff @(posedge wb_clk_i) begin
    if (timer == '0) begin
      if (wb_stb_i & wb_cyc_i) begin
        timer <= timer + 1'b1;
      end
    end else begin
      if (wb_ack_o) begin
        timer <= '0;
      end else begin
        timer <= timer + 1'b1;
      end
    end
  end

  // Violates handshake by pulling cmd_valid low without a cmd_ready on timeout
  always_comb begin
    cmd_valid = 1'b0;
    rsp_ready = 1'b0;
    wb_dat_o[7:0] = timeout ? '0 : rsp_data;
    unique case (wb_adr_i[1:0])
      2'd1: begin
        rsp_ready = ~wb_we_i & wb_stb_i & wb_cyc_i;
        wb_ack_o = rsp_valid & rsp_ready | timeout;
      end
      2'd2: begin
        cmd_valid = wb_we_i & wb_stb_i & wb_cyc_i;
        wb_ack_o = cmd_valid & cmd_ready | timeout;
      end
      default: begin
        wb_dat_o[7:0] = {Version, 2'b00, ~rsp_valid, ~cmd_ready};
        wb_ack_o = wb_stb_i & wb_cyc_i;
      end
    endcase
  end

  stream_fifo #(
      .DataWidth(8),
      .DataDepth(FifoDepth)
  ) rsp_fifo_u (
      .clock_i  (wb_clk_i),
      .reset_i  (wb_rst_i),
      .s_valid_i(wr_valid),
      .s_ready_o(wr_ready),
      .s_data_i (wr_data),
      .m_valid_o(rsp_valid),
      .m_ready_i(rsp_ready),
      .m_data_o (rsp_data)
  );

  stream_fifo #(
      .DataWidth(8),
      .DataDepth(FifoDepth)
  ) cmd_fifo_u (
      .clock_i  (wb_clk_i),
      .reset_i  (wb_rst_i),
      .s_valid_i(cmd_valid),
      .s_ready_o(cmd_ready),
      .s_data_i (cmd_data),
      .m_valid_o(rd_valid),
      .m_ready_i(rd_ready),
      .m_data_o (rd_data)
  );

  // The core requires an initial reset (but shouldnt)
  logic [3:0] reset = '0;
  always_ff @(posedge wb_clk_i) begin
    reset <= {reset[2:0], 1'b1};
  end

  ucaspian ucaspian_u (
      .sys_clk(wb_clk_i),
      .reset(wb_rst_i | ~reset[3]),
      .write_data(wr_data),
      .write_vld(wr_valid),
      .write_rdy(wr_ready),
      .read_data(rd_data),
      .read_vld(rd_valid),
      .read_rdy(rd_ready),
      .led_0(led_o[0]),
      .led_1(led_o[1]),
      .led_2(led_o[2]),
      .led_3(led_o[3])
  );

endmodule
