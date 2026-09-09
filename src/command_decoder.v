module command_decoder(
    input clk,
    input reset,

    input [7:0] fifo_data,
    input       fifo_empty,

    output      fifo_rd_en,
    output reg  start_cmd,
    output reg  stop_cmd
);

    // -----------------------------------------------------------
    // fifo_rd_en is now COMBINATIONAL instead of registered.
    //
    // Why this changed (bug found during integration review):
    // In the original version, fifo_rd_en was a registered output.
    // That means when the decoder saw a non-empty FIFO on cycle N,
    // it only asked the FIFO to pop on cycle N+1 -- but fifo.v's
    // data_out is a combinational "peek" of the CURRENT front entry,
    // so the same byte was still visible on cycle N+1 too. The
    // decoder would then decode that same byte a second time before
    // the pop (armed on cycle N) actually took effect on the FIFO at
    // the START of cycle N+1. Net effect: the very first byte after
    // the FIFO goes from empty->non-empty was decoded for TWO clock
    // cycles instead of one (start_cmd/stop_cmd glitched high for
    // 2 cycles instead of 1).
    //
    // Making fifo_rd_en purely combinational (fifo_rd_en = !fifo_empty)
    // means the read request and the decode both happen in the SAME
    // cycle the byte is visible, so the FIFO pops on the very next
    // clock edge and the front-of-queue value has already advanced
    // by the time the decoder looks again. Each byte is now decoded
    // exactly once, for exactly one clock cycle.
    // -----------------------------------------------------------
    assign fifo_rd_en = !fifo_empty;

    always @(posedge clk) begin

        if (reset) begin
            start_cmd <= 1'b0;
            stop_cmd  <= 1'b0;
        end

        else begin

            // Default outputs are LOW.
            // Commands become HIGH for only one clock cycle.
            start_cmd <= 1'b0;
            stop_cmd  <= 1'b0;

            // If the FIFO has a byte available this cycle,
            // decode it (it will be popped this same cycle
            // via the combinational fifo_rd_en above).
            if (!fifo_empty) begin

                // ASCII 'S' = 8'h53
                if (fifo_data == 8'h53) begin
                    start_cmd <= 1'b1;
                end

                // ASCII 'P' = 8'h50
                else if (fifo_data == 8'h50) begin
                    stop_cmd <= 1'b1;
                end

            end

        end

    end

endmodule