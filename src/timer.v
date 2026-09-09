module timer(
    input clk,
    input reset,
    input tick,
    input load,
    input [4:0] load_value,

    output reg [4:0] timer
    );

    always @(posedge clk) begin
        if(reset)
            timer <= 0;
        else if(load)
            timer <= load_value;
        else if(tick) begin
            if(timer > 0)
                timer <= timer - 1;
            else
                timer <= 0;
        end
    end

endmodule