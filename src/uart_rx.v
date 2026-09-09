module uart_rx #(
    parameter CLKS_PER_BIT = 10417
)(
    input  clk,
    input  reset,
    input  rx,

    output reg [7:0] data_out,
    output reg       data_valid
);

    // UART receiver states
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    // State register
    reg [1:0] state;

    // UART RX synchronizer
    // Synchronizes the external RX signal to clk
    reg rx_sync_0;
    reg rx_sync_1;

    always @(posedge clk) begin
        if (reset) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end
        else begin
            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;
        end
    end

    // ------------------------------------------------
    // Counters and data storage
    // ------------------------------------------------

    // Counts FPGA clock cycles within one UART bit
    reg [13:0] clk_count;

    // Counts received bits: 0 to 7
    reg [2:0] bit_index;

    // Temporarily stores the received byte
    reg [7:0] rx_shift;

    // UART receiver
    always @(posedge clk) begin

        if (reset) begin

            state      <= IDLE;
            clk_count  <= 14'd0;
            bit_index  <= 3'd0;
            rx_shift   <= 8'd0;
            data_out   <= 8'd0;
            data_valid <= 1'b0;

        end

        else begin

            // data_valid is normally LOW.
            // It becomes HIGH for one clock cycle
            // when a complete byte is received.
            data_valid <= 1'b0;

            case (state)

                // ====================================
                // IDLE
                // Wait for start bit
                IDLE: begin

                    clk_count <= 14'd0;
                    bit_index <= 3'd0;

                    // UART idle line = HIGH
                    // Start bit = LOW
                    if (rx_sync_1 == 1'b0) begin
                        state     <= START;
                        clk_count <= 14'd0;
                    end

                end


                // START
                // Verify that the detected LOW signal
                // is actually the middle of a start bit
                START: begin

                    if (clk_count == (CLKS_PER_BIT / 2)) begin

                        if (rx_sync_1 == 1'b0) begin

                            // Valid start bit
                            state     <= DATA;
                            clk_count <= 14'd0;
                            bit_index <= 3'd0;

                        end

                        else begin

                            // False start
                            state     <= IDLE;
                            clk_count <= 14'd0;

                        end

                    end

                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // DATA
                // Receive 8 data bits
                DATA: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 14'd0;

                        // UART transmits LSB first
                        rx_shift[bit_index] <= rx_sync_1;

                        if (bit_index == 3'd7) begin

                            // All 8 bits received
                            bit_index <= 3'd0;
                            state     <= STOP;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                        end

                    end

                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // STOP
                // Check stop bit
                STOP: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 14'd0;
                        state     <= IDLE;

                        // Stop bit should be HIGH
                        if (rx_sync_1 == 1'b1) begin

                            data_out   <= rx_shift;
                            data_valid <= 1'b1;

                        end

                    end

                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end


                // Safety
                default: begin

                    state     <= IDLE;
                    clk_count <= 14'd0;
                    bit_index <= 3'd0;
                    rx_shift  <= 8'd0;

                end

            endcase

        end

    end

endmodule