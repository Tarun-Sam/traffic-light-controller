// =============================================================
// Synchronous FIFO
// 8-bit wide, 16-entry deep
// -------------------------------------------------------------
// Design choices (see chat explanation for full reasoning):
//   - Counter-based full/empty detection (simple, synthesizable,
//     easier to reason about than the "extra pointer bit" trick).
//   - "Peek-then-pop" read interface: data_out combinationally
//     shows the current front-of-queue value at all times.
//     Asserting rd_en for one cycle "pops" that value and
//     advances to the next one.
//   - Synchronous, active-high reset (matches timer.v style).
//   - Write-when-full and read-when-empty are safely ignored
//     (no corruption, no crash) -- this will be exercised by
//     the testbench.
// =============================================================

module fifo (
    input        clk,
    input        reset,      // synchronous, active-high

    // Write side
    input        wr_en,
    input  [7:0] data_in,

    // Read side
    input        rd_en,
    output [7:0] data_out,

    // Status flags
    output       full,
    output       empty
    );

    // -----------------------------------------------------------
    // Storage array: 16 mailboxes, each 8 bits wide.
    // This is the FIFO's internal RAM. Pointers move around it;
    // data itself never shifts between slots.
    // -----------------------------------------------------------
    reg [7:0] mem [0:15];

    // -----------------------------------------------------------
    // Pointers: 4 bits is exactly enough to index 0-15.
    // wr_ptr = slot that will be written to NEXT
    // rd_ptr = slot that will be read from NEXT (the "front")
    // -----------------------------------------------------------
    reg [3:0] wr_ptr;
    reg [3:0] rd_ptr;

    // -----------------------------------------------------------
    // count: how many valid entries are currently stored (0-16).
    // Needs 5 bits because it must be able to represent the
    // value 16 itself (4 bits alone would max out at 15).
    // This single register is what makes full/empty detection
    // simple and unambiguous.
    // -----------------------------------------------------------
    reg [4:0] count;

    // -----------------------------------------------------------
    // Status flags: pure combinational functions of count.
    // -----------------------------------------------------------
    assign full  = (count == 5'd16);
    assign empty = (count == 5'd0);

    // -----------------------------------------------------------
    // Read data: combinational "peek" at the front of the queue.
    // Always valid to look at, even when empty (in that case it
    // just shows stale/old data -- the empty flag is what tells
    // the reader whether that data is meaningful).
    // -----------------------------------------------------------
    assign data_out = mem[rd_ptr];

    // -----------------------------------------------------------
    // Main sequential block: pointers, count, and memory writes
    // all update together on the clock edge.
    // -----------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
            count  <= 5'd0;
            // Note: we do NOT clear mem[] on reset.
            // Old data becomes irrelevant once count/pointers
            // are reset -- clearing 16 registers would just be
            // wasted reset logic in real silicon.
        end
        else begin
            // ---------------------------------------------------
            // Handle write and read together so that a
            // simultaneous write+read in the same cycle is
            // handled correctly (count should NOT change, but
            // both pointers still move).
            // ---------------------------------------------------
            case ({ (wr_en && !full), (rd_en && !empty) })
                2'b10: begin // write only
                    mem[wr_ptr] <= data_in;
                    wr_ptr      <= wr_ptr + 4'd1;
                    count       <= count + 5'd1;
                end
                2'b01: begin // read only
                    rd_ptr <= rd_ptr + 4'd1;
                    count  <= count - 5'd1;
                end
                2'b11: begin // simultaneous write and read
                    mem[wr_ptr] <= data_in;
                    wr_ptr      <= wr_ptr + 4'd1;
                    rd_ptr      <= rd_ptr + 4'd1;
                    count       <= count; // net change is zero
                end
                default: begin // 2'b00 - no valid operation
                    // nothing changes
                end
            endcase
        end
    end

endmodule