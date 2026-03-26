`define ENTRY_WIDTH 8
`define LENGTH      32
`define PTR_WIDTH   5
module Fifo (
  input Rd_en,Wr_en,clk,rst,
  input  [`ENTRY_WIDTH-1:0] Dat_In,
  output reg [`ENTRY_WIDTH-1:0] Dat_Out
);
  
  reg [`ENTRY_WIDTH-1:0] Fifo_mem [`LENGTH-1:0];
  reg [`PTR_WIDTH-1+1:0] wr_ptr,rd_ptr;
  integer i;
  wire full,empty,equality;
 
  assign equality = wr_ptr[`PTR_WIDTH] == rd_ptr[`PTR_WIDTH];
  assign empty = equality & (wr_ptr[`PTR_WIDTH-1:0] == rd_ptr[`PTR_WIDTH-1:0]);
  assign full  = ~equality & (wr_ptr[`PTR_WIDTH-1:0] == rd_ptr[`PTR_WIDTH-1:0]);
  
  always @(posedge clk) begin
    if (rst) begin
      for (i=0; i<`LENGTH; i=i+1) begin
        Fifo_mem[i] <= `ENTRY_WIDTH'h0;  // dimensiunea este de 8 biti
      end 
      wr_ptr  <= {1'b0,`PTR_WIDTH'h0};
    end else if (Wr_en & ~full) begin
      Fifo_mem[wr_ptr[`PTR_WIDTH-1:0]] <= Dat_In;  // dimensiunea este de 8 biti
      wr_ptr <= wr_ptr + `PTR_WIDTH'h1;
    end else begin
      Fifo_mem[wr_ptr[`PTR_WIDTH-1:0]] <= Fifo_mem[wr_ptr[`PTR_WIDTH-1:0]];  // dimensiunea este de 8 biti
    end
  end
  
  
  always @(posedge clk) begin
    if (rst) begin
      Dat_Out <= 8'b0;  // dimensiunea este de 8 biti
      rd_ptr  <= {1'b0,`PTR_WIDTH'h0};
    end else if (Rd_en & ~empty) begin
      Dat_Out <= Fifo_mem[rd_ptr[`PTR_WIDTH-1:0]];  // dimensiunea este de 8 biti
      rd_ptr <= rd_ptr + `PTR_WIDTH'h1;
    end else begin
      Dat_Out <= Dat_Out;  // dimensiunea este de 8 biti
      rd_ptr  <= rd_ptr;
    end
  end

endmodule
