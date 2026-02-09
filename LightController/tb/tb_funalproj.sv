`timescale 1ns/1ps
`define CLOCK_PERIOD 10
`define SIM_CYCLES (1000 * `CLOCK_PERIOD)
`include "/home/fananiae/projects/Light_controller/final_proj.v"

module tb_final_proj;

  // Clocking
  logic clk ;
//  always #5 clk = ~clk; // 100 MHz
  int cyc_counter = 0;                    // Folosit in numararea ciclurilor

  // Reset and tick
  logic rst;
  logic tick;

  // DUT outputs
  logic NS_Red, NS_Yel, NS_Grn;
  logic EW_Red, EW_Yel, EW_Grn;
  logic [2:0] CntrlLight;

 initial begin
   rst = 1;
 end
 initial begin
 #50  rst = 0;
 end

  // Instantiate DUT
  Traffic_FSM dut (
    .clk(clk),
    .rst(rst),
    .tick(tick),
    .CntrlLight(CntrlLight)
  );

  int tick_cnt;
  always_ff @(posedge clk) begin
    if (rst) begin
      tick_cnt <= 0;
      tick     <= 1'b0;
    end else begin
      tick_cnt <= tick_cnt + 1;
      if (tick_cnt == 9) begin
        tick <= 1'b1;
        tick_cnt <= 0;
      end else begin
        tick <= 1'b0;
      end
    end
  end

 initial begin
   clk = 0;
   forever begin
     #(`CLOCK_PERIOD/2) clk = ~clk;
     cyc_counter = cyc_counter+1;
   end
 end
  // Simple stimulus
  initial begin
      $fsdbDumpfile("inter.fsdb");
      $fsdbDumpvars(0);
    $dumpfile("tb_final_proj.vcd");
   // $dumpvars(0, tb_final_proj);
    $dumpvars(1);
    #`SIM_CYCLES $display ("Test done!\n");

    $finish;
  end

endmodule
