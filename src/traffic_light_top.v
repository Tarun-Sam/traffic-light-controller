module traffic_light_top(
    input clk,
    input start_btn,
    input stop_btn,
    input reset,
    input rx,               // NEW: UART serial data in from PC/terminal

    output led_r,
    output led_g,

    output [6:0] segments,
    output [7:0] anodes
    );

    //internal wires
    wire tick;
    wire timer_tick;
    wire [4:0] timer_value;
    wire load_timer;
    wire [4:0] load_value;
    wire paused;

    // Debounced / edge-detected button pulses
    wire start_clean;
    wire stop_clean;
    wire reset_clean;

    // ---------------------------------------------------------
    // NEW: UART -> FIFO -> command decoder wires
    // ---------------------------------------------------------
    wire [7:0] uart_data;        // byte received by uart_rx
    wire       uart_data_valid;  // 1-cycle pulse: uart_data is valid

    wire       fifo_wr_en;       // write request into fifo
    wire       fifo_full;
    wire       fifo_empty;
    wire       fifo_rd_en;       // read request out of fifo
    wire [7:0] fifo_data;        // byte currently at front of fifo

    wire       uart_start;       // 1-cycle pulse: 'S' decoded
    wire       uart_stop;        // 1-cycle pulse: 'P' decoded

    // Combined control pulses that actually drive the FSM
    wire       start_to_fsm;
    wire       stop_to_fsm;

    button_debounce start_debounce(
        .clk(clk),
        .btn_raw(start_btn),
        .btn_clean(start_clean)
    );

    button_debounce stop_debounce(
        .clk(clk),
        .btn_raw(stop_btn),
        .btn_clean(stop_clean)
    );

    button_debounce reset_debounce(
        .clk(clk),
        .btn_raw(reset),
        .btn_clean(reset_clean)
    );

    // 1Hz tick generator
    clock_divider divider(
        .clk(clk),
        .reset(reset_clean),
        .tick(tick)
    );

    // Countdown timer only advances when not paused
    assign timer_tick = tick & ~paused;

    // Countdown timer
    timer countdown(
        .clk(clk),
        .reset(reset_clean),
        .tick(timer_tick),
        .load(load_timer),
        .load_value(load_value),
        .timer(timer_value)
    );

    // ---------------------------------------------------------
    // Combine physical buttons and UART commands.
    //
    // start_clean/stop_clean (from button_debounce) and
    // uart_start/uart_stop (from command_decoder) are BOTH
    // single-clock-cycle pulses, so a plain OR gives the FSM
    // one combined pulse no matter which source triggered it.
    // The UART path never touches the FSM's internal state
    // directly -- it only feeds the same start/stop inputs the
    // physical buttons already used.
    // ---------------------------------------------------------
    assign start_to_fsm = start_clean | uart_start;
    assign stop_to_fsm  = stop_clean  | uart_stop;

    // Traffic light FSM
    traffic_fsm fsm(
        .clk(clk),
        .reset(reset_clean),
        .start(start_to_fsm),
        .stop(stop_to_fsm),
        .timer(timer_value),
        .led_r(led_r),
        .led_g(led_g),
        .load_timer(load_timer),
        .load_value(load_value),
        .paused(paused)
    );

    // Seven-segment countdown display
    seven_segment display(
    .clk(clk),
    .value(timer_value),
    .segments(segments),
    .anodes(anodes)
    );

    // ---------------------------------------------------------
    // NEW: UART receiver
    // 100 MHz system clock, 9600 baud -> CLKS_PER_BIT = 10417
    // ---------------------------------------------------------
    uart_rx #(
        .CLKS_PER_BIT(10417)
    ) uart_rx_inst (
        .clk(clk),
        .reset(reset_clean),
        .rx(rx),
        .data_out(uart_data),
        .data_valid(uart_data_valid)
    );

    // ---------------------------------------------------------
    // NEW: command FIFO
    // Write a byte in whenever uart_rx has a valid byte and the
    // FIFO isn't full. If it's full and a byte is dropped, that's
    // acceptable for this simple control-command use case.
    // ---------------------------------------------------------
    assign fifo_wr_en = uart_data_valid & ~fifo_full;

    fifo fifo_inst (
        .clk(clk),
        .reset(reset_clean),
        .wr_en(fifo_wr_en),
        .data_in(uart_data),
        .rd_en(fifo_rd_en),
        .data_out(fifo_data),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    // ---------------------------------------------------------
    // NEW: command decoder
    // Turns 'S'/'P' bytes pulled from the FIFO into single-cycle
    // start/stop pulses for the FSM.
    // ---------------------------------------------------------
    command_decoder cmd_decoder_inst (
        .clk(clk),
        .reset(reset_clean),
        .fifo_data(fifo_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .start_cmd(uart_start),
        .stop_cmd(uart_stop)
    );

endmodule