/* uCaspian DP RAM
 * Parker Mitchell, 2019
 *
 * This implements a basic dual port SRAM in a 16x256 configuration.
 * It is intended to hold accumulated charge but currently does
 * not have any specialized functionality beyond a simple DP RAM.
 */

module dp_ram_16x256(
    input               clk,
    input               reset,

    // Read Port
    input         [7:0] rd_addr,
    input               rd_en,
    output logic [15:0] rd_data,

    // Write Port
    input         [7:0] wr_addr,
    input               wr_en,
    input  logic [15:0] wr_data
);

logic [15:0] ram [255:0];

always_ff @(posedge clk) begin
    // Read before write
    if(~reset & rd_en) rd_data <= ram[rd_addr];
    if(~reset & wr_en) ram[wr_addr] <= wr_data;
end

endmodule

module dp_ram_24x256(
    input               clk,
    input               reset,

    // Read Port
    input         [7:0] rd_addr,
    input               rd_en,
    output logic [23:0] rd_data,

    // Write Port
    input         [7:0] wr_addr,
    input               wr_en,
    input  logic [23:0] wr_data
);

logic [23:0] ram [255:0];

always_ff @(posedge clk) begin
    // Read before write
    if(~reset & rd_en) rd_data <= ram[rd_addr];
    if(~reset & wr_en) ram[wr_addr] <= wr_data;
end

endmodule

module dp_ram_16x1024(
    input               clk,
    input               reset,

    // Read Port
    input         [9:0] rd_addr,
    input               rd_en,
    output logic [15:0] rd_data,

    // Write Port
    input         [9:0] wr_addr,
    input               wr_en,
    input  logic [15:0] wr_data
);

logic [15:0] ram [1023:0];

always_ff @(posedge clk) begin
    // Read before write
    if(~reset & rd_en) rd_data <= ram[rd_addr];
    if(~reset & wr_en) ram[wr_addr] <= wr_data;
end

endmodule
