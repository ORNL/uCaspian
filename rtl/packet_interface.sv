/* uCaspian Packet Interface 
 * Parker Mitchell, 2019
 *
 * This packet interface is designed to deal with a low bandwidth
 * variable length packet format. The packet interface also
 * incorporates some system-level state control.
 */
`ifndef uCaspian_Packet_Interface_SV
`define uCaspian_Packet_Interface_SV

module packet_interface(
    input               clk,
    input               reset,

    // misc control signals
    input               core_active,
    output logic        ack_sent,
    output logic        led,

    // clear state
    output logic        clear_act,
    output logic        clear_config,
    input               clear_done,

    // network time
    input               time_remaining,
    input       [31:0]  time_current,
    input               time_update,
    output logic        time_sent,

    output logic [7:0]  time_target_value,
    output logic        time_target_waiting,
    input               time_target_ack,

    // output fire interface
    input        [7:0]  output_fire_addr,
    input               output_fire_waiting,
    output logic        output_fire_sent,

    // input fire interface
    output logic [7:0]  input_fire_addr,
    output logic [7:0]  input_fire_value,
    output logic        input_fire_waiting,
    input               input_fire_ack,

    // configuration interface
    output logic [11:0] cfg_addr,
    output logic        cfg_synapse,
    output logic [11:0] cfg_value,
    output logic [2:0]  cfg_byte,
    input               cfg_done,

    // metric interface
    output logic [7:0]  metric_addr,
    input        [7:0]  metric_value,
    output logic        metric_read,
    input               metric_send,

    // Host -> uCaspian
    input        [7:0]  rx_packet_data,
    input               rx_packet_vld,
    output logic        rx_packet_rdy,

    // uCaspian -> Host
    output logic [7:0]  tx_packet_data,
    output logic        tx_packet_vld,
    input               tx_packet_rdy
);

localparam [2:0] MAX_CFG_BYTE = 7;

localparam [7:0]
    OP_NOOP      = 8'b00000000,
    OP_STEP      = 8'b00000001,
    OP_METRIC    = 8'b00000010,
    OP_CLR_ACT   = 8'b00000100,
    OP_CLR_CFG   = 8'b00000101,
    OP_CFG_NE    = 8'b00001000,
    OP_CFG_SYN   = 8'b00010000,
    OP_CFG_SYNS  = 8'b00010001;

// Rx state machine
localparam [2:0]
    RX_IDLE      = 0,
    RX_FIRE      = 1,
    RX_STEP      = 2,
    RX_CFG_NE    = 3,
    RX_CFG_SYN   = 4,
    RX_METRIC    = 5,
    RX_CLEAR_ACT = 6,
    RX_CLEAR_CFG = 7;

logic [2:0]  rx_state;
logic [2:0]  rx_read_bytes;
logic [7:0]  rx_opcode;

logic cfg_read_done;
logic metric_sent;

initial rx_state = RX_IDLE;
initial metric_sent = 0;

always_comb led = (rx_state == RX_IDLE);

always @(posedge clk) begin
    rx_state            <= rx_state;
    rx_packet_rdy       <= 0;
    time_target_waiting <= 0;
    time_target_value   <= 0;
    clear_act           <= 0;
    clear_config        <= 0;

    case(rx_state)
        RX_IDLE: begin
            rx_read_bytes <= 0;
            cfg_addr      <= 0;
            cfg_value     <= 0;
            cfg_synapse   <= 0;
            cfg_byte      <= MAX_CFG_BYTE;
            rx_packet_rdy <= 1;
            cfg_read_done <= 0;
            metric_read   <= 0;

            input_fire_waiting <= 0;
            input_fire_addr    <= 0;
            input_fire_value   <= 0;

            // Wait for time
            if(time_remaining || time_update || (time_update && output_fire_waiting)) begin
                rx_packet_rdy <= 0;
            end
            // Wait for a packet
            else if(rx_packet_rdy && rx_packet_vld) begin
                rx_opcode     <= rx_packet_data;
                rx_packet_rdy <= 0;
                // Decode the desired operation
                case(rx_packet_data)
                    //OP_NOOP:     rx_state <= RX_IDLE;
                    OP_STEP:     rx_state <= RX_STEP;
                    OP_METRIC:   rx_state <= RX_METRIC;
                    OP_CLR_ACT:  rx_state <= RX_CLEAR_ACT;
                    OP_CLR_CFG:  rx_state <= RX_CLEAR_CFG;
                    OP_CFG_NE:   rx_state <= RX_CFG_NE;
                    OP_CFG_SYN:  rx_state <= RX_CFG_SYN;
                    OP_CFG_SYNS: rx_state <= RX_CFG_SYN;
                    default: begin
                        if(rx_packet_data[7]) begin
                            rx_state <= RX_FIRE;
                        end
                        else begin
                            rx_state      <= RX_IDLE;
                            rx_packet_rdy <= 1;
                        end
                    end
                endcase
            end
        end
        RX_FIRE: begin
            // Send an input fire to the uCaspian core
            if(input_fire_waiting) begin
                if(input_fire_ack) begin
                    input_fire_waiting <= 0;
                    rx_state           <= RX_IDLE;
                end
                else begin
                    input_fire_waiting <= 1;
                    rx_state           <= RX_FIRE;
                end
            end
            else if(rx_packet_rdy && rx_packet_vld) begin
                input_fire_addr    <= {1'b0, rx_opcode[6:0]};
                input_fire_value   <= rx_packet_data;
                input_fire_waiting <= 1;
            end
            else begin
                rx_packet_rdy <= 1;
            end
        end
        RX_STEP: begin
            // Advance the target time by the specified number of steps
            //   Note: this is relative to the current target time
            if(time_target_waiting) begin
                if(time_target_ack) begin
                    time_target_waiting <= 0;
                    time_target_value   <= 0;
                    rx_state            <= RX_IDLE;
                end
                else begin
                    time_target_waiting <= time_target_waiting;
                    time_target_value   <= time_target_value;
                end
            end
            else if(rx_packet_rdy && rx_packet_vld) begin
                time_target_value   <= rx_packet_data;
                time_target_waiting <= 1;
            end
            else begin
                rx_packet_rdy <= 1;
            end
        end
        RX_CFG_NE: begin
            // Configure the specified neuron
            if(cfg_read_done) begin
                cfg_addr      <= 0;
                cfg_value     <= 0;
                cfg_byte      <= MAX_CFG_BYTE;
                rx_packet_rdy <= 0;
                rx_state      <= RX_IDLE;
            end
            else if(rx_packet_rdy && rx_packet_vld) begin
                rx_read_bytes <= rx_read_bytes + 1;
                cfg_read_done <= 0;
                case(rx_read_bytes)
                    0: begin
                        cfg_addr[7:0]   <= rx_packet_data;
                        cfg_byte        <= 0;
                    end
                    // Threshold
                    1: begin
                        cfg_value[11:8] <= 0;
                        cfg_value[7:0]  <= rx_packet_data;
                        cfg_byte        <= 1;
                    end
                    // Axonal Delay,  Output Enable, Leak
                    //     [7:4]           [3]       [2:0]
                    2: begin
                        cfg_value[11:8] <= 0;
                        cfg_value[7:0]  <= rx_packet_data;
                        cfg_byte        <= 2;
                    end
                    // Synapse start
                    3: begin
                        cfg_value[11:8] <= rx_packet_data[3:0];
                        cfg_value[7:0]  <= 0;
                        cfg_byte        <= 3;
                    end
                    4: begin
                        cfg_value[7:0]  <= rx_packet_data;
                        cfg_byte        <= 4;
                    end
                    // Synapse count
                    5: begin
                        cfg_value[11:8] <= 0;
                        cfg_value[7:0]  <= rx_packet_data;
                        cfg_byte        <= 5;
                        cfg_read_done   <= 1;
                    end
                    default: begin
                        rx_packet_rdy <= 0;
                        cfg_read_done <= 1;
                        rx_state      <= RX_IDLE;
                    end
                endcase
            end
            else begin
                rx_packet_rdy <= 1;
            end
        end
        RX_CFG_SYN: begin
            // Configure the specified synapse
            //   Currently just one, but there are plans...
            cfg_synapse <= 1;
            if(cfg_read_done) begin
                cfg_addr      <= 0;
                cfg_value     <= 0;
                cfg_byte      <= MAX_CFG_BYTE;
                rx_packet_rdy <= 0;
                rx_state      <= RX_IDLE;
            end
            else if(rx_packet_rdy && rx_packet_vld) begin
                rx_read_bytes <= rx_read_bytes + 1;
                cfg_read_done <= 0;
                case(rx_read_bytes)
                    // Synapse address
                    0: begin
                        cfg_addr[11:8] <= rx_packet_data[3:0];
                        cfg_byte       <= 0;
                    end
                    1: begin
                        cfg_addr[7:0]  <= rx_packet_data;
                        cfg_byte       <= 1;
                    end
                    // Synaptic weight
                    2: begin
                        cfg_value[11:8] <= 0;
                        cfg_value[7:0]  <= rx_packet_data;
                        cfg_byte        <= 2;
                    end
                    // Target neuron address
                    3: begin
                        cfg_value[11:8] <= 0;
                        cfg_value[7:0]  <= rx_packet_data;
                        cfg_byte        <= 3;
                        cfg_read_done   <= 1;
                    end
                    default: begin
                        rx_packet_rdy <= 0;
                        cfg_read_done <= 1;
                        rx_state      <= RX_IDLE;
                    end
                endcase
            end
            else begin
                rx_packet_rdy <= 1;
            end
        end
        RX_METRIC: begin
            // Request the specified metric register
            if(metric_sent) begin
                metric_read <= 0;
                rx_state    <= RX_IDLE;
            end
            else if(!metric_read) begin
                if(rx_packet_rdy && rx_packet_vld) begin
                    metric_addr <= rx_packet_data;
                    metric_read <= 1;
                end
                else begin
                    rx_packet_rdy <= 1;
                end
            end
        end
        RX_CLEAR_ACT: begin
            // Clear activity in the network
            clear_act <= 1;
            if(ack_sent) begin
                clear_act <= 0;
                rx_state  <= RX_IDLE;
            end
        end
        RX_CLEAR_CFG: begin
            // Clear the configuration in the core
            clear_config <= 1;
            if(ack_sent) begin
                clear_config <= 0;
                rx_state     <= RX_IDLE;
            end
        end
        default: begin
            rx_state <= RX_IDLE;
        end
    endcase

    if(reset) begin
        rx_read_bytes <= 0;
        cfg_addr      <= 0;
        cfg_value     <= 0;
        cfg_synapse   <= 0;
        cfg_byte      <= MAX_CFG_BYTE;
        rx_packet_rdy <= 1;
        cfg_read_done <= 0;
        rx_opcode     <= 0;
        rx_state      <= RX_IDLE;
    end
end

// Tx state machine
localparam [2:0]
    TX_IDLE      = 0,
    TX_FIRE      = 1,
    TX_STEP      = 2,
    TX_ACK_CFG   = 3,
    TX_METRIC    = 4,
    TX_ACK_CLR   = 5;

logic [2:0] tx_state;
logic [2:0] tx_state_reg;
logic [2:0] tx_write_bytes;
logic [7:0] tx_data;

logic ack_sent_sig, time_sent_sig, metric_sent_sig, out_fire_sent_sig;
logic step_send, tx_send;

initial tx_state = TX_IDLE;

always_ff @(posedge clk) begin
    if(reset) begin
        tx_state_reg     <= TX_IDLE;
        ack_sent         <= 0;
        time_sent        <= 0;
        metric_sent      <= 0;
        output_fire_sent <= 0;
        tx_packet_data   <= 0;
        tx_packet_vld    <= 0;
        tx_write_bytes   <= 0;
    end
    else begin
        tx_state_reg <= tx_state;

        ack_sent         <= ack_sent_sig;
        time_sent        <= time_sent_sig;
        metric_sent      <= metric_sent_sig;
        output_fire_sent <= out_fire_sent_sig;

        // Transmit control
        if(tx_state == TX_IDLE) begin
            tx_packet_data <= 0;
            tx_packet_vld  <= 0;
            tx_write_bytes <= 0;
        end
        else if(tx_packet_rdy && tx_send) begin
            tx_packet_data <= tx_data;
            tx_packet_vld  <= 1;
            tx_write_bytes <= tx_write_bytes + 1; 
        end
        else begin
            tx_packet_data <= tx_packet_data;
            tx_packet_vld  <= 0;
            tx_write_bytes <= tx_write_bytes;
        end
    end
end

logic [7:0] output_fire_addr_reg;
always_ff @(posedge clk) begin
    if(tx_state_reg == TX_FIRE) begin
        if(tx_write_bytes == 0) begin
            output_fire_addr_reg <= output_fire_addr;
        end
    end
    else begin
        output_fire_addr_reg <= 0;
    end
end

logic [31:0] tx_time_reg;
always_ff @(posedge clk) begin
    if(tx_state_reg == TX_STEP) begin
        if(tx_write_bytes == 0) begin
            tx_time_reg <= time_current;
        end
    end
    else begin
        tx_time_reg <= 0;
    end
end

always_comb begin
    // default to keeping the same state
    tx_state = tx_state_reg;
    tx_data  = tx_packet_data;
    tx_send  = 0;

    // ack signals
    ack_sent_sig      = 0;
    time_sent_sig     = 0;
    metric_sent_sig   = 0;
    out_fire_sent_sig = 0;
    
    step_send = time_update && (!time_remaining || output_fire_waiting);

    case(tx_state_reg)

        TX_IDLE: begin
            if(step_send)                tx_state = TX_STEP;
            else if(output_fire_waiting) tx_state = TX_FIRE;
            else if(metric_send)         tx_state = TX_METRIC;
            else if(cfg_done)            tx_state = TX_ACK_CFG;
            else if(clear_done)          tx_state = TX_ACK_CLR;
        end

        TX_FIRE: begin
            tx_send = (tx_write_bytes < 2);
            out_fire_sent_sig = ~tx_send;

            case(tx_write_bytes)
                0: tx_data  = 8'b10000000;
                1: tx_data  = output_fire_addr_reg;
            endcase

            // end of state
            if(!tx_send && output_fire_sent) tx_state = TX_IDLE;
        end

        TX_STEP: begin
            tx_send = (tx_write_bytes < 5);
            time_sent_sig = ~tx_send;

            case(tx_write_bytes)
                0: tx_data  = 8'b00000001;
                1: tx_data  = tx_time_reg[31:24]; // time_current[31:24];
                2: tx_data  = tx_time_reg[23:16]; // time_current[23:16];
                3: tx_data  = tx_time_reg[15:8];  // time_current[15:8];
                4: tx_data  = tx_time_reg[7:0];   // time_current[7:0];
            endcase

            // end of state
            if(!tx_send && time_sent) tx_state = TX_IDLE;
        end

        TX_METRIC: begin
            tx_send = (tx_write_bytes < 3);
            metric_sent_sig = ~tx_send;

            case(tx_write_bytes)
                0: tx_data  = 8'b00000010;
                1: tx_data  = metric_addr;
                2: tx_data  = metric_value;
            endcase

            // end of state
            if(!tx_send && metric_sent && !metric_read) tx_state = TX_IDLE;
        end

        TX_ACK_CFG: begin
            tx_send = (tx_write_bytes == 0);
            ack_sent_sig = ~tx_send;

            case(tx_write_bytes)
                0: tx_data  = 8'b00011000;
            endcase

            // end of state
            if(!tx_send && ack_sent) tx_state = TX_IDLE;
        end

        TX_ACK_CLR: begin
            tx_send = (tx_write_bytes == 0);
            ack_sent_sig = ~tx_send;

            case(tx_write_bytes)
                0: tx_data  = 8'b00000100;
            endcase

            // end of state
            if(!tx_send && ack_sent) tx_state = TX_IDLE;
        end
        
        default: begin
            tx_state = TX_IDLE;
        end
    endcase
end


endmodule
`endif
