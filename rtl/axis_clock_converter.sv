`include "synchronizer.sv"

module axis_clock_converter(
    input  reset,

    input  s_axis_aclk,
    input  s_axis_tvalid,
    output s_axis_tready,
    input  [DATA_WIDTH-1:0] s_axis_tdata,

    output m_axis_aclk,
    output m_axis_tvalid,
    input  m_axis_tready,
    output [DATA_WIDTH-1:0] m_axis_tdata
);
parameter DATA_WIDTH = 512;

// Internal signals
logic s_valid_toggle;
logic m_valid_toggle;
logic m_valid_toggle_f;

logic s_ready;
logic [DATA_WIDTH-1:0] s_data;

logic s_read_toggle;
logic m_read_toggle;

logic m_read_pulse;
logic m_valid;
logic m_valid_l;

// State Machine Signals
typedef enum { S_IDLE, S_SEND } s_state_t;
s_state_t s_state = S_IDLE;

//------------------------------------------------------------------------------
//---- Synchronizers
//------------------------------------------------------------------------------

// Synchronizer to convert the valid toggle from the S clock domain to the M clock domain.
synchronizer #(.RESET_VALUE(0), .NUM_FLIP_FLOPS(2)) valid_sync(
    .reset(reset),
    .clk(m_axis_aclk),
    .data_in(s_valid_toggle),
    .data_out(m_valid_toggle)
);

// Synchronizer to convert the read toggle from the M clock domain to the S clock domain.
synchronizer #(.RESET_VALUE(0), .NUM_FLIP_FLOPS(2)) read_sync(
    .reset(reset),
    .clk(s_axis_aclk),
    .data_in(m_read_toggle),
    .data_out(s_read_toggle)
);

//------------------------------------------------------------------------------
//---- S Clock Domain
//------------------------------------------------------------------------------

// Flip-Flop to hold the information that will cross the clock domain.
always_ff @(posedge s_axis_aclk, posedge reset) begin
    if (reset) begin
        s_data <= DATA_WIDTH'h0;
    end
    else begin
        if (s_ready == 1'b1) begin
            s_data <= s_axis_tdata;
        end
    end
end

// State machine to handle control signals in the S clock domain.
logic previous_s_read_toggle;
always_ff @(posedge s_axis_aclk, posedge reset) begin
    // Inputs to state machine
    //    s_axis_tvalid
    //    s_read_toggle

    // Outputs to state machine
    //    s_valid_toggle
    //    s_ready
    if (reset) begin
        s_valid_toggle         <= 0;
        s_state                <= S_IDLE;
        previous_s_read_toggle <= 0;
    end
    else begin
        unique case(s_state)

            // When idle look for valid axis input, and toggle the valid
            // line to signal to the M domain state machine.
            S_IDLE: begin
                if (s_axis_tvalid == 1) begin
                    s_state <= S_SEND;
                    s_valid_toggle <= ~s_valid_toggle;
                end
            end

            // When in the send state listen for a read toggle to
            // acknowledge the send.
            S_SEND: begin
                if (s_read_toggle != previous_s_read_toggle) begin
                    previous_s_read_toggle <= s_read_toggle;
                    s_state <= S_IDLE;
                end
            end
        endcase
    end
end

// Signals controlled by state of machine
always_latch begin
    if (reset) begin
        s_ready <= 0;
    end
    else begin
        unique case(s_state)
            S_IDLE: begin
                s_ready <= 1;
            end
            S_SEND: begin
                s_ready <= 0;
            end
        endcase
    end
end

// Set external s_axis_tready
assign s_axis_tready = s_ready;

//------------------------------------------------------------------------------
//---- M Clock Domain
//------------------------------------------------------------------------------

// Generate a read pulse from a toggle on the m_valid_toggle line.
always_ff @(posedge m_axis_aclk, posedge reset) begin
    if (reset) begin
        m_valid_toggle_f <= 0;
    end
    else begin
        m_valid_toggle_f <= m_valid_toggle;
    end
end
assign m_read_pulse = m_valid_toggle ^ m_valid_toggle_f;

// m_axis data is set to the s_data
// A pass-through is fine since the valid signal is delayed through
// synchronization logic and s_data is constant until acknowledged.
assign m_axis_tdata = s_data;

// Valid signal is passed through to reduce cycles needed.
assign m_valid = m_read_pulse | m_valid_l;

// Set/clear flip-flop for m_valid signal
always_ff @(posedge m_axis_aclk, posedge reset) begin
    if (reset) begin
        m_valid_l <= 0;
        m_read_toggle <= 0;
    end
    else begin
        // Clear valid and toggle read
        // Clear is given priority over the set
        if (m_axis_tready == 1 && m_valid == 1) begin
            m_valid_l <= 0;
            m_read_toggle <= ~m_read_toggle;
        end

        // Set valid
        else if (m_read_pulse == 1) begin
            m_valid_l <= 1;
        end
    end
end

// Set external tvalid
assign m_axis_tvalid = m_valid;

endmodule