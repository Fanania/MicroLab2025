module Traffic_FSM (
    input  clk,
    input  rst,
    input  tick,               // puls 1Hz
    output reg NS_Red, NS_Yel, NS_Grn,
    output reg EW_Red, EW_Yel, EW_Grn,
    output [2:0] state_out
);

    // ---- Stari FSM ----
    localparam NS_GREEN  = 3'd0;
    localparam NS_YELLOW = 3'd1;
    localparam EW_GREEN  = 3'd2;
    localparam EW_YELLOW = 3'd3;

    // ---- Timpi în secunde ----
    localparam T_GREEN  = 10;
    localparam T_YELLOW = 3;

    reg [2:0] state, next_state;
    reg [2:0] prev_state;

    // ---- Pulse pentru resetul timerului ----
    wire rst_timer;
    assign rst_timer = (state != prev_state);   // Pulse de 1 ciclu la intrarea in stare

    wire Done;
    wire [15:0] left;
    wire timer_active;

    // ---- Timer instantiat, durata e dată de starea curentă ----
    // Observatie: schimbăm parametrul TIMER_sec la runtime printr-un multiplexer
    reg [15:0] duration_val;

    always @(*) begin
        case (state)
            NS_GREEN :  duration_val = T_GREEN;
            NS_YELLOW: duration_val = T_YELLOW;
            EW_GREEN :  duration_val = T_GREEN;
            EW_YELLOW: duration_val = T_YELLOW;
            default  : duration_val = T_GREEN;
        endcase
    end

    // Timer simplificat
    TIMER_sec timer_inst (
        .clk(clk),
        .rst(rst_timer | rst),
        .tick(tick),
        .Load_sec(duration_val),
        .Active(timer_active),
        .Done(Done),
        .left(left)
    );
    defparam timer_inst.DURATION = 10; // fallback daca Load_sec e 0

    // ---- Next State Logic ----
    always @(*) begin
        next_state = state;
        case (state)
            NS_GREEN:   if (Done) next_state = NS_YELLOW;
            NS_YELLOW:  if (Done) next_state = EW_GREEN;
            EW_GREEN:   if (Done) next_state = EW_YELLOW;
            EW_YELLOW:  if (Done) next_state = NS_GREEN;
        endcase
    end

    // ---- State Register ----
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= NS_GREEN;
            prev_state <= 3'd7;
        end else begin
            prev_state <= state;
            state      <= next_state;
        end
    end

    // ---- Output Logic ----
    always @(*) begin
        NS_Red=0; NS_Yel=0; NS_Grn=0;
        EW_Red=0; EW_Yel=0; EW_Grn=0;

        case (state)
            NS_GREEN:   begin NS_Grn=1; EW_Red=1; end
            NS_YELLOW:  begin NS_Yel=1; EW_Red=1; end
            EW_GREEN:   begin EW_Grn=1; NS_Red=1; end
            EW_YELLOW:  begin EW_Yel=1; NS_Red=1; end
            default:    begin NS_Red=1; EW_Red=1; end
        endcase
    end

    assign state_out = state;

endmodule
