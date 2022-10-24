module fifo(
    input                     clk,
    input                     reset,
    input                     write_enable,
    input        [WIDTH-1:0]  write_data,
    input                     read_enable,
    output logic [WIDTH-1:0]  read_data,
    output logic              almost_full,
    output logic              empty,
    output logic              full,
    output logic [7:0]        count,
    output logic [7:0]        avail,
);
parameter WIDTH = 8;
parameter DEPTH = 512;

localparam DEPTH_BITS = $clog2(DEPTH);

logic [WIDTH-1:0] bram[0:DEPTH-1];
logic [DEPTH_BITS-1:0] write_ptr;
logic [DEPTH_BITS-1:0] read_ptr;
logic [DEPTH_BITS:0] cur_size;

wire empty_sig = (cur_size == 0);
wire full_sig  = (cur_size == DEPTH);

always_comb count = cur_size;
always_comb avail = (DEPTH-cur_size);

always_ff @(posedge clk)
    almost_full <= (cur_size >= DEPTH-10);

always_comb empty = empty_sig;
always_comb full  = full_sig;

wire wr_en = write_enable && !full_sig;
wire rd_en = read_enable && !empty_sig;

always_comb read_data = bram[read_ptr];
//always_comb read_data = (empty && read_enable) ? 0 : bram[read_ptr];

always @(posedge clk) begin
    if (reset) begin
        write_ptr <= 0;
        read_ptr  <= 0;
        cur_size  <= 0;
    end else begin
        if(wr_en && !rd_en) begin
            cur_size <= cur_size + 1;
        end
        else if(!wr_en && rd_en) begin
            cur_size <= cur_size - 1;
        end

        if (wr_en) begin
            bram[write_ptr] <= write_data;
            write_ptr       <= write_ptr + 1;
        end
        if (rd_en) begin
            read_ptr  <= read_ptr + 1;
        end
    end
end
endmodule