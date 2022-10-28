/*
 * Copyright 2020 Brett Witherspoon
 */

module stream_fifo #(
    parameter int DataWidth = 8,
    parameter int DataDepth = 512
) (
    input logic clock_i,
    input logic reset_i,

    input  logic                 s_valid_i,
    output logic                 s_ready_o = 1,
    input  logic [DataWidth-1:0] s_data_i,

    output logic                 m_valid_o = 0,
    input  logic                 m_ready_i,
    output logic [DataWidth-1:0] m_data_o
);
  typedef logic [$clog2(DataDepth):0] addr_t;
  typedef logic [DataWidth-1:0] data_t;

  typedef enum logic [1:0] {
    EMPTY,
    FETCH,
    VALID
  } state_e;

  state_e r_state = EMPTY;

  addr_t w_addr_q = '0;
  addr_t r_addr_q = '0;

  addr_t w_addr_d;
  addr_t r_addr_d;

  data_t w_data[2**($bits(w_addr_q)-1)];
  data_t r_data;

  wire m_write = s_valid_i & s_ready_o;
  wire s_stall = m_valid_o & ~m_ready_i;
  wire r_empty = r_addr_q == w_addr_q;

  wire w_full = w_addr_d == {~r_addr_q[$bits(r_addr_q)-1], r_addr_q[$bits(r_addr_q)-2:0]};

  always_comb begin
    w_addr_d = w_addr_q + 1'b1;
    r_addr_d = r_addr_q + 1'b1;
  end

  always_ff @(posedge clock_i) begin
    if (reset_i) begin
      w_addr_q <= '0;
    end else if (m_write) begin
      w_addr_q <= w_addr_d;
    end
  end

  always_ff @(posedge clock_i) begin
    if (reset_i) begin
      s_ready_o <= 1;
    end else if (m_write && !(r_state == VALID && ~s_stall)) begin
      s_ready_o <= w_full ? 0 : 1;
    end else if (!m_write && (r_state == VALID && ~s_stall)) begin
      s_ready_o <= 1;
    end
  end

  always_ff @(posedge clock_i) begin
    if (reset_i) begin
      r_state  <= EMPTY;
      r_addr_q <= '0;
    end else begin
      unique case (r_state)
        EMPTY: begin
          if (m_write) begin
            r_state <= FETCH;
          end
        end
        FETCH: begin
          r_state  <= VALID;
          r_addr_q <= r_addr_d;
        end
        VALID: begin
          if (~s_stall) begin
            if (r_empty) begin
              r_state <= m_write ? FETCH : EMPTY;
            end else begin
              r_addr_q <= r_addr_d;
            end
          end
        end
        default;
      endcase
    end
  end

  always_ff @(posedge clock_i) begin
    if (reset_i) begin
      m_valid_o <= 0;
    end else if (!s_stall) begin
      m_valid_o <= r_state == VALID;
    end
  end

  always_ff @(posedge clock_i) begin
    if (!s_stall) begin
      m_data_o <= r_data;
    end
  end

  // Synchronous dual-port RAM
  always_ff @(posedge clock_i) begin
    if (m_write) begin
      w_data[w_addr_q[$bits(w_addr_q)-2:0]] <= s_data_i;
    end
  end

  always_ff @(posedge clock_i) begin
    if (!s_stall || (r_state == FETCH)) begin
      r_data <= w_data[r_addr_q[$bits(r_addr_q)-2:0]];
    end
  end

endmodule
