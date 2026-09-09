module seven_segment(
    input clk,
    input [4:0] value,     
    output reg [6:0] segments,
    output reg [7:0] anodes
    );

    wire [3:0] tens  = value / 10;
    wire [3:0] units = value % 10;
    reg [15:0] refresh_count = 0;
    
    always @(posedge clk) begin
        refresh_count <= refresh_count + 1;
    end

    wire digit_sel = refresh_count[15]; 
    reg [3:0] active_digit;

    always @(*) begin
        if(digit_sel) begin
            active_digit = tens;
            anodes = 8'b11111101;  
        end
        else begin
            active_digit = units;
            anodes = 8'b11111110;  
        end
    end

    always @(*) begin
        case(active_digit)
            4'd0: segments = 7'b1000000; 
            4'd1: segments = 7'b1111001; 
            4'd2: segments = 7'b0100100; 
            4'd3: segments = 7'b0110000; 
            4'd4: segments = 7'b0011001; 
            4'd5: segments = 7'b0010010; 
            4'd6: segments = 7'b0000010; 
            4'd7: segments = 7'b1111000; 
            4'd8: segments = 7'b0000000; 
            4'd9: segments = 7'b0010000; 

            default: segments = 7'b1111111;  
        endcase
    end

endmodule