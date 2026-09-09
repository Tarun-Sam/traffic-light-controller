module clock_divider #(
    parameter ROLLOVER = 99_999_999   // default: 1 tick/sec @ 100 MHz clk
)(
    input clk,
    input reset,
    output reg tick = 0
    );

    reg [26:0] count = 0;

    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            tick <= 0;
        end
        else if (count == ROLLOVER) begin
            count <= 0;
            tick <= 1;
        end
        else begin
            count <= count + 1;
            tick <= 0;
        end
    end

endmodule