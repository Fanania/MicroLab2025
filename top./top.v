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
                        parameter integer DIV     = CLK_HZ / TICK_HZ   // Merge ca localparam
                       )(
  input      clk,
  input      rst,
  output reg tick                                // Puls de un 1 ciclu pe TICK_HZ
);

  // Avem nevoie de un counter. Vrem tick la secunda deci la 1 Hz
  reg  [31:0] cnt;    // Pentru 50 MHz 26 de biti ar trebui sa fie destuli
  wire [31:0] cnt_up;
  wire        Treshold;
  
  assign  Treshold     = cnt[31:0] >= DIV-1; // Poate fi facut mai destept. 
  assign  cnt_up[31:0] = cnt[31:0] + 32'b1;
  always @(posedge clk) begin // cred ca merge un reste asincron
    if (rst) begin
      cnt[31:0] <= 32'd0;
      tick      <=  1'b0;
    end else if (Treshold) begin
      cnt[31:0] <= 32'd0;
      tick      <=  1'b1;
    end else begin
      cnt[31:0] <= cnt_up[31:0];
      tick      <=  1'b0;
    end
  end
endmodule

// ---------------- TIMER ----------------
// Acum sa folosim tickul de mai sus 
module TIMER_sec (
  input       clk,
  input       rst,
  input       tick,                                // Puls de un 1 ciclu pe TICK_HZ
  input       en,                                  // Enable
  input [15:0]Load_sec,                            // Setam cat sa dureze culoarea
  output      Active,                              // Asserted cat timp se numara
  output reg  Done,         
  output reg [15:0] left                           // pt debug
);

wire        En_Count;
wire        En_Load;
wire [15:0] left_up;
wire        Decrease;

 assign En_Count      = Active & tick;             // Update la secunda
 assign En_Load       = en & ~running;             // Facem load cand primim en din exterior. running deasertat pana la load 
 assign Decrease      = |left[15:1]                // daca am scazut pana la unu, trecem pe zero
 assign left_up[15:0] = (Decrease) ? left[15:0] - 15'd1        // Poate fi optimizat dar e mai simplu de inteles asa
                                   : 16'd0   
                                   ;
 assign Active        = running;

 always @(posedge clk) begin
   if (rst) begin
     left[15:0] <= 16'd0;
     runnig     <= 1'b0;
     Done       <= 1'b0;
   end else if (En_Load) begin
     left[15:0] <= Load_sec[15:0];
     running    <= 1'b1;
     Done       <= 1'b0;     
   end else if (En_Count) begin 
     left[15:0] <= left_up[15:0];
     running    <= ~Decrease;
     Done       <= ~Decrease;  
   end else begin
     left[15:0] <= left[15:0];
     running    <= runnig;
     Done       <= Done;     
   end
 end
endmodule

// ---------------- FSM Semafor ----------------
// Acum Fsm-ul

module Traffic_FSM (
  input clk,
  input rst,
  input tick,
  output reg NS_Red, NS_Yel, NS_Grn,
  output reg EW_Red, EW_Yel, EW_Grn,
  output reg [2:0] state_out
);

  // parametri timpi (secunde)
  localparam T_GREEN  = 16'd10;
  localparam T_YELLOW = 16'd3;
  localparam T_RED    = 16'd1;

  reg [2:0] state, next_state;
  reg en;
  reg [15:0] Load_sec;

  wire Active, Done;
  wire [15:0] left;

  // Timer instanțiat
  TIMER_sec timer(
    .clk(clk),
    .rst(rst),
    .tick(tick),
    .en(en),
    .Load_sec(Load_sec),
    .Active(Active),
    .Done(Done),
    .left(left)
  );

  // FSM - Next State Logic
  always @(*) begin
    next_state = state;
    en         = 1'b0;
    Load_sec   = 16'd0;

    case (state)
      `NS_GREEN: begin
        if (Done) begin
          next_state = `NS_YELLOW;
          en       = 1'b1;
          Load_sec = T_YELLOW;
        end
      end
      `NS_YELLOW: begin
        if (Done) begin
          next_state = `EW_GREEN;
          en       = 1'b1;
          Load_sec = T_GREEN;
        end
      end
      `EW_GREEN: begin
        if (Done) begin
          next_state = `EW_YELLOW;
          en       = 1'b1;
          Load_sec = T_YELLOW;
        end
      end
      `EW_YELLOW: begin
        if (Done) begin
          next_state = `NS_GREEN;
          en       = 1'b1;
          Load_sec = T_GREEN;
        end
      end
      default: begin
        next_state = `NS_GREEN;
        en       = 1'b1;
        Load_sec = T_GREEN;
      end
    endcase
  end

  // FSM - State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= `NS_GREEN;
      en    <= 1'b1;
      Load_sec <= T_GREEN;
    end else begin
      state <= next_state;
    end
  end

  // Output Logic (luminile semaforului)
  always @(*) begin
    NS_Red = 0; NS_Yel = 0; NS_Grn = 0;
    EW_Red = 0; EW_Yel = 0; EW_Grn = 0;

    case (state)
      `NS_GREEN:  begin NS_Grn=1; EW_Red=1; end
      `NS_YELLOW: begin NS_Yel=1; EW_Red=1; end
      `EW_GREEN:  begin EW_Grn=1; NS_Red=1; end
      `EW_YELLOW: begin EW_Yel=1; NS_Red=1; end
      default:    begin NS_Red=1; EW_Red=1; end
    endcase
  end

  assign state_out = state;

endmodule
