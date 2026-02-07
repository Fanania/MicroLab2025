// Semafor in verilog 
// Intersectia Tudor e aici:). Intersectie cu 4 puncte semaforizate (A,B,C,D)
// Pe Bulevardul Tudor Vladimirescu pe directia Nord->Sud. se intersecteaza cu bulvardul Mangeron si bulverdul Chimie pe Est>Vest
// Fiecare semafor are 3 iesiri: rosu, galben si verde.
// CLK_HZ parametrizabil cu defaultul pe 50_000_000 (50 MHz)
`timescale 1ns/1ps
//----------------------> zona pentru defineuri<------------------------
`define NS_GREEN   3'd0
`define NS_YELLOW  3'd1
`define NS_RED     3'd2
`define EW_GREEN   3'd3
`define EW_YELLOW  3'd4
`define EW_RED     3'd5
//----------------------------------------------------------------------

// ---------------- TICK generator ----------------
// Prima data avem nevoie de un generator de clock. Pe FPGA clockul fizic este foarte rapid 50/100 MHz
// daca noi planificam sa tinem un semafor verde pentru 20 de secunde, am avea nevoie de un numarator imens pe frecventa clockului de pe FPGA
// Ce face TICK_generator:
//  - La clk rapid de 50 MHz, il imparte la un factor configuarbil (ex. 50 mil ->1 Hz)
//  - genereaza un tick care pulseaza o data pe secunda
module TICK_generator #(parameter integer CLK_HZ  = 50_000_000,
                        parameter integer TICK_HZ = 1,
                        parameter integer DIV     = CLK_HZ / TICK_HZ
                       )(
  input      clk,
  input      rst,
  output reg tick
);
  wire Treshold;
  reg [31:0] cnt;
  reg [31:0] cnt_up;
  assign Treshold     = (cnt >= DIV-1);
  assign cnt_up[31:0] = cnt[31:0] + 32'h1;
  always @(posedge clk) begin
    if (rst) begin
      tick      <=  1'b0;
      cnt[31:0] <= 32'h0;
    end else if (Treshold) begin   // la treshold trebuie sa mergem inapoi
      tick      <= 1'b1;
      cnt[31:0] <= 32'h0;      
    end else begin
      tick      <= 1'b0;
      cnt[31:0] <= cnt_up[31:0];      
    end
  end
endmodule

// ---------------- TIMER ----------------
// Acum sa folosim tickul de mai sus
// Load la en (semnal de puls) scade la fiecare tick 


module TIMER_sec #(parameter integer DURATION = 10)   // durata fixa în secunde
                  (
  input        clk,
  input        rst,
  input        tick,
  input  [15:0] Load_sec,
  output reg   Done,         
  output reg [15:0] left
);

  reg running;

  assign Active = running;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      left    <= Load_sec;
      Done    <= 1'b0;
    end else begin
      if (tick) begin
        if (left > 1) begin
          left <= left - 1;
          Done <= left;
        end else begin
          left    <= 0;
          Done    <= 1'b1;   // expirat
        end
      end
    end
  end
endmodule

module Traffic_FSM (
    input  clk,
    input  rst,
    input  tick,
    output [2:0]CntrlLight 
);
    reg [15:0] duration_val;
    wire[15:0] Load_sec;

    // ---- Stari FSM ----
    localparam NS_GREEN  = 3'd0;
    localparam NS_YELLOW = 3'd1;
    localparam EW_GREEN  = 3'd2;
    localparam EW_YELLOW = 3'd3;

    // ---- Timpi in secunde ----
    localparam T_GREEN  = 10;
    localparam T_YELLOW = 3;

    // Registrii FSM
    reg [2:0] state_out;
    reg [2:0] state_in;
    reg [15:0] left;
    wire rst_timer;
    // Timer simplificat
    TIMER_sec timer_inst (
        .clk(clk),
        .rst(rst_timer | rst),
        .tick(tick),
        .Load_sec(duration_val),
        .Done(Done),
        .left(left)
    );
    assign rst_timer = state_in != state_out;
    // Actualizare combinationala a state=ului
    always @* begin
      case (state_out)  // ultima valoare actualizata
        NS_GREEN  :if (Done)  state_in = NS_YELLOW;     // De fiecare data cand e verde -> urmeaza galben
        NS_YELLOW :if (Done)  state_in = EW_GREEN;      // De fiecare data cand e galben -> urmeaza rosu -> deci vered pentru directia opusa
        EW_GREEN  :if (Done)  state_in = EW_YELLOW;
        EW_YELLOW :if (Done)  state_in = NS_GREEN;
        default   :           state_in = state_out;
      endcase
    end

    always @(*) begin
      case (state_out)
          NS_GREEN :  duration_val = T_GREEN;
          NS_YELLOW: duration_val = T_YELLOW;
          EW_GREEN :  duration_val = T_GREEN;
          EW_YELLOW: duration_val = T_YELLOW;
          default  : duration_val = T_GREEN;
      endcase
    end
    assign Load_sec[15:0] = duration_val[15:0];

    // Structura FSM -> actaulizare constanta
    always @(posedge clk) begin
      if (rst) begin
        state_out[2:0] <= 2'h0;
      end else begin
        state_out[2:0] <= state_in[2:0];      
      end
    end

    assign CntrlLight[2:0] = state_out[2:0];

endmodule


