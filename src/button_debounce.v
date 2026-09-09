module button_debounce #(
    parameter STABLE_COUNT = 999_999   // default: ~10ms @ 100 MHz clk
)(
    input clk,
    input btn_raw,

    output reg btn_clean
    );

    reg btn_sync_0, btn_sync_1;
    reg [19:0] stable_count = 0;
    reg btn_stable = 0;
    reg btn_stable_prev = 0;

    always @(posedge clk) begin
        btn_sync_0 <= btn_raw;
        btn_sync_1 <= btn_sync_0;
    end

    always @(posedge clk) begin
        if(btn_sync_1 == btn_stable)
            stable_count <= 0;
        else begin
            stable_count <= stable_count + 1;
            if(stable_count == STABLE_COUNT) begin
                btn_stable <= btn_sync_1;
                stable_count <= 0;
            end
        end
    end

    always @(posedge clk) begin
        btn_stable_prev <= btn_stable;
        btn_clean <= btn_stable & ~btn_stable_prev;
    end

endmodule