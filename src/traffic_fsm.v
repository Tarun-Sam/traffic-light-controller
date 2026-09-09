module traffic_fsm(
    input clk,
    input reset,
    input start,
    input stop,
    input [4:0] timer,

    output reg led_r,
    output reg led_g,

    output reg load_timer,
    output reg [4:0] load_value,

    output reg paused

    );

    // New sequence: IDLE -> GREEN(20s) -> YELLOW(2s) -> RED(20s) -> GREEN -> ... (loops forever)
    parameter IDLE = 2'b00, GREEN = 2'b01, YELLOW = 2'b10, RED = 2'b11;

    reg [1:0] ps;
    reg [1:0] ns;

    // Block 1 : State Register
    always @(posedge clk) begin
        if(reset)
            ps <= IDLE;
        else
            ps <= ns;
    end

    // Block 2 : Pause Register
    // stop_btn pauses (freezes state + countdown) instead of forcing IDLE.
    // start_btn resumes from wherever it was paused.
    // reset always clears pause and forces IDLE (handled in Block 1).
    always @(posedge clk) begin
        if(reset)
            paused <= 0;
        else if(stop)
            paused <= 1;
        else if(start)
            paused <= 0;
    end

    // Block 3 : Next State Logic
    always @(*) begin
        case(ps)
            IDLE: begin
                if(start)
                    ns = GREEN;
                else
                    ns = IDLE;
            end

            GREEN: begin
                if(timer == 0)
                    ns = YELLOW;
                else
                    ns = GREEN;
            end

            YELLOW: begin
                if(timer == 0)
                    ns = RED;
                else
                    ns = YELLOW;
            end

            RED: begin
                if(timer == 0)
                    ns = GREEN;
                else
                    ns = RED;
            end

            default:
                ns = IDLE;

        endcase

        // While paused, hold the current state regardless of timer value.
        if(paused)
            ns = ps;

    end

    // Block 4 : Output Logic (RGB LED)
    always @(*) begin

        led_r = 0;
        led_g = 0;

        case(ps)

            IDLE: ;      // both off

            GREEN:
                led_g = 1;

            YELLOW: ;    // both off, no color during yellow

            RED:
                led_r = 1;

        endcase

     end

    // Block 5 : Timer Load Logic
    always @(*) begin

        load_timer = 0;
        load_value = 0;

        if(ps != ns) begin
            load_timer = 1;
            case(ns)
                GREEN:
                    load_value = 20;
                YELLOW:
                    load_value = 2;
                RED:
                    load_value = 20;
                default:
                    load_value = 0;
            endcase
        end

    end

endmodule