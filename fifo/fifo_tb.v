// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module fifo_tb;
  reg        Rd_en;
  reg        Wr_en;
  reg        clk;
  reg        rst;
  reg  [7:0] Dat_In;
  wire [7:0] Dat_Out;

  integer errors;
  integer i;

  // DUT
  Fifo dut (
    .Rd_en(Rd_en),
    .Wr_en(Wr_en),
    .clk(clk),
    .rst(rst),
    .Dat_In(Dat_In),
    .Dat_Out(Dat_Out)
  );

  // 100 MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  task do_reset;
    begin
      rst   = 1'b1;
      Rd_en = 1'b0;
      Wr_en = 1'b0;
      Dat_In = 8'h00;
      repeat (2) @(posedge clk);
      rst = 1'b0;
      @(posedge clk);
    end
  endtask

  task write_byte(input [7:0] value);
    begin
      @(negedge clk);
      Wr_en  = 1'b1;
      Dat_In = value;
      Rd_en  = 1'b0;
      @(posedge clk);
      #1;
      Wr_en  = 1'b0;
    end
  endtask

  task read_byte_and_check(input [7:0] expected);
    begin
      @(negedge clk);
      Rd_en = 1'b1;
      Wr_en = 1'b0;
      @(posedge clk);
      #1;
      if (Dat_Out !== expected) begin
        $display("[ERROR] t=%0t expected Dat_Out=0x%02h, got=0x%02h", $time, expected, Dat_Out);
        errors = errors + 1;
      end else begin
        $display("[OK]    t=%0t Dat_Out=0x%02h", $time, Dat_Out);
      end
      Rd_en = 1'b0;
    end
  endtask

  initial begin
    errors = 0;

    $display("--- FIFO testbench start ---");

    // 1) Reset
    do_reset();

    // 2) Basic write/read ordering test
    for (i = 0; i < 8; i = i + 1)
      write_byte(i + 8'h10);

    for (i = 0; i < 8; i = i + 1)
      read_byte_and_check(i + 8'h10);

    // 3) Fill FIFO to capacity and attempt one extra write
    do_reset();
    for (i = 0; i < 32; i = i + 1)
      write_byte(i[7:0]);

    // This write should be ignored when FIFO is full
    write_byte(8'hAA);

    // Drain and verify only first 32 values are present
    for (i = 0; i < 32; i = i + 1)
      read_byte_and_check(i[7:0]);

    // 4) Underflow attempt: read from empty FIFO, output should hold last value
    @(negedge clk);
    Rd_en = 1'b1;
    @(posedge clk);
    #1;
    if (Dat_Out !== 8'h1F) begin
      $display("[ERROR] t=%0t expected hold Dat_Out=0x1F on empty read, got=0x%02h", $time, Dat_Out);
      errors = errors + 1;
    end
    Rd_en = 1'b0;

    if (errors == 0)
      $display("--- TEST PASSED ---");
    else
      $display("--- TEST FAILED: %0d error(s) ---", errors);

    #20;
    $finish;
  end
endmodule
