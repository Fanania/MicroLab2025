
module MUX4TO1 (
  input      [7:0] in0,in1,in2,in3,
  input      [1:0] sel,
  input            clk,rst,
  output reg [7:0] out
  );
  
  wire [7:0] reg_mux;
  assign reg_mux[7:0] = {8{~|sel[1:0]}}        & in0[7:0]
                      | {8{~sel[1] &  sel[0]}} & in1[7:0]
                      | {8{ sel[1] & ~sel[0]}} & in2[7:0]
                      | {8{&sel[1:0]}}         & in3[7:0]
                      ;

  always @(posedge clk) begin
    if (rst ) begin
      out[7:0] <= 7'h0;
    end else begin
      out[7:0] <= reg_mux[7:0];
    end
  end

endmodule

// Un FIFO („First-In, First-Out”) este o structura de date folosita pentru a transmite date intre două blocuri...
//..care pot produce sau consuma date la momente diferite. 
// Funcționeaza ca o coada: primul element introdus este primul scos.

module FIFO (
 input      [7:0] wr_data,
 input            clk,rst,
 input            rd_en,wr_en,
 output reg [7:0] rd_data
 );

 reg [7:0] fifo_mem [31:0]; // 32 de intrari a cate 8 biti
 reg [5:0] wr_ptr, rd_ptr;
 wire      full;            // semnal care indica fifo plin -> nu se mai scrie
 wire      empty;           // semnal care indica fifo plin -> nu se mai citeste\
 wire      eq_ptr;

 assign eq_ptr = wr_ptr[4:0] == rd_ptr[4:0];
 assign full   =  (wr_ptr[5]^rd_ptr[5]) & eq_ptr;
 assign empty  = ~(wr_ptr[5]^rd_ptr[5]) &  eq_ptr;               // FIFO este gol cand nimic nu a fost scris sau cand tot ce s-a scris a fost citit
 ////// WRITE WRITE WRITE WRITE WRITE //////
 always @(posedge clk) begin
   if (rst) begin
     wr_ptr[5:0] <= 6'h0;                                        // Curatare ptr     
   end else if (full | ~wr_en) begin
     fifo_mem[wr_ptr[4:0]][7:0] <= fifo_mem[wr_ptr[4:0]][7:0];   // Nu mai scrie
     wr_ptr[5:0]                <= wr_ptr[5:0];                  // Pastreaza pointerul
   end else begin 
     fifo_mem[wr_ptr[4:0]][7:0] <= wr_data[7:0];                 // Updateaza zona indicata
     wr_ptr[5:0]                <= wr_ptr[5:0] + 6'h1;           // Pointerul de scriere avanseaza circular (cand ajunge la capat, revine la 0).
   end
 end
 ////// READ READ READ READ RAED ////////
 always @(posedge clk) begin
   if (rst) begin
     rd_ptr[5:0]  <= 6'h0;
     rd_data[7:0] <= 8'h0;
   end else if (empty | ~rd_en) begin
     rd_data[7:0] <= rd_data[7:0];
     rd_ptr [5:0] <= rd_ptr[5:0];
   end else begin
     rd_data[7:0] <= fifo_mem[rd_ptr[4:0]][7:0];
     rd_ptr [5:0] <= rd_ptr[5:0] + 6'h1;                     // Pointerul de scriere avanseaza circular (cand ajunge la capat, revine la 0).
   end
 end

endmodule

module FIFO_MUX_TOP (
  input        clk,
  input        rst,
  input        rd_en,
  input        wr_en,
  input  [1:0] sel,
  input  [7:0] in0,
  input  [7:0] in1,
  input  [7:0] in2,
  input  [7:0] in3,
  output [7:0] rd_data
);
  wire [7:0] mux_out;

  MUX4TO1 u_mux (
    .clk (clk),
    .rst (rst),
    .sel (sel),
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .in3 (in3),
    .out (mux_out)
  );

  FIFO u_fifo (
    .clk     (clk),
    .rst     (rst),
    .rd_en   (rd_en),
    .wr_en   (wr_en),
    .wr_data (mux_out),
    .rd_data (rd_data)
  );
endmodule

