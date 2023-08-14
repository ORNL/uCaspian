`timescale 1ns / 1ps

module ucaspian_wb_tb;
  localparam OPCODE_CLEAR_ACTIVITY = 8'b00000100;

  logic        wb_clk_i;
  logic        wb_rst_i = 0;
  logic [29:0] wb_adr_i = '0;
  logic [31:0] wb_dat_i;
  logic [31:0] wb_dat_o;
  logic [ 3:0] wb_sel_i = '1;
  logic        wb_we_i = 1'b0;
  logic        wb_stb_i = 1'b0;
  logic        wb_cyc_i = 1'b0;
  logic        wb_ack_o;
  logic [ 3:0] led_o;

  ucaspian_wb dut (.*);

  // 100 MHz
  initial begin
    wb_clk_i <= 1'b0;
    forever #1ns wb_clk_i = ~wb_clk_i;
  end

  task watchdog(int timeout = 100000);
    #(timeout) $fatal(1, "Timeout");
  endtask

  task wb_reset(input int hold = 3);
    begin
      @(negedge wb_clk_i) wb_rst_i = 1;
      repeat (3) @(negedge wb_clk_i);
      wb_rst_i = 0;
    end
  endtask

  task wb_read(input logic [29:0] adr, output logic [31:0] dat);
    begin
      wb_adr_i = adr;
      wb_we_i  = 1'b0;
      wb_stb_i = 1'b1;
      wb_cyc_i = 1'b1;
      wait (wb_ack_o) @(posedge wb_clk_i) dat = wb_dat_o;
      wb_we_i  = 1'b0;
      wb_stb_i = 1'b0;
      wb_cyc_i = 1'b0;
      #1;
    end
  endtask

  task wb_write(input logic [29:0] adr, input logic [31:0] dat);
    begin
      wb_adr_i = adr;
      wb_dat_i = dat;
      wb_we_i  = 1'b1;
      wb_stb_i = 1'b1;
      wb_cyc_i = 1'b1;
      wait (wb_ack_o) @(posedge wb_clk_i);
      wb_we_i  = 1'b0;
      wb_stb_i = 1'b0;
      wb_cyc_i = 1'b0;
      #1;
    end
  endtask

  logic [31:0] data;

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("ucaspian_wb_tb.dump");
      $dumpvars(0, dut);
    end

    wb_reset();

    fork
      watchdog(10000);
    join_none

    wb_read(30'd0, data);
    assert (data[1:0] === 2'b10) else begin
      $fatal(1, "data: %0h != %0h", data, 2'b10);
    end

    wb_write(30'd2, OPCODE_CLEAR_ACTIVITY);

    wb_read(30'd1, data);
    assert (data[7:0] === OPCODE_CLEAR_ACTIVITY) else begin
      $fatal(1, "data: %0h != %0h", data, OPCODE_CLEAR_ACTIVITY);
    end

    disable watchdog;

    repeat (10) @(negedge wb_clk_i);

    $fclose($fopen("ucaspian_wb_tb.pass", "w"));
    $finish;
  end

endmodule
