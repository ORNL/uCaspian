module ucaspian_tb;
    timeunit 1ns;
    timeprecision 1ps;

    // 25MHz
    bit sys_clk = 0;
    initial forever #0.2ns sys_clk = ~sys_clk;

    bit reset = 0;
    initial begin
        @(negedge sys_clk) reset = 1;
        repeat (3) @(negedge sys_clk);
        reset = 0;
    end

    logic [7:0] write_data;
    logic write_vld;
    logic write_rdy;

    logic [7:0] read_data;
    logic read_rdy;
    logic read_vld;

    logic led_0;
    logic led_1;
    logic led_2;
    logic led_3;

    ucaspian dut(
        .sys_clk,
        .reset,
        .write_data,
        .write_vld,
        .write_rdy,
        .read_data,
        .read_rdy,
        .read_vld,
        .led_0,
        .led_1,
        .led_2,
        .led_3
    );

    initial begin
`ifdef __ICARUS__
        $dumpfile("ucaspian_tb.fst");
        $dumpvars(0, ucaspian_tb);
`endif	
        repeat (10) @(negedge sys_clk);
        $finish;
    end

endmodule
