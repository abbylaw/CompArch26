module top(
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

    // 12 MHz clock, so 2,000,000 cycles is 1/6 second
    parameter COLOR_INTERVAL = 2000000;

    logic [$clog2(COLOR_INTERVAL) - 1:0] count = 0;
    logic [2:0] color = 0;

    always_ff @(posedge clk) begin
        if (count == COLOR_INTERVAL - 1) begin
            count <= 0;

            if (color == 5) begin
                color <= 0;
            end
            else begin
                color <= color + 1;
            end
        end
        else begin
            count <= count + 1;
        end
    end

    always_comb begin
        case (color)
            0: begin
                RGB_R = 0;
                RGB_G = 1;
                RGB_B = 1;
            end

            1: begin
                RGB_R = 0;
                RGB_G = 0;
                RGB_B = 1;
            end

            2: begin
                RGB_R = 1;
                RGB_G = 0;
                RGB_B = 1;
            end

            3: begin
                RGB_R = 1;
                RGB_G = 0;
                RGB_B = 0;
            end

         4: begin
                RGB_R = 1;
                RGB_G = 1;
                RGB_B = 0;
            end

            5: begin
                RGB_R = 0;
                RGB_G = 1;
                RGB_B = 0;
            end
            
            default: begin
            RGB_R = 1;
            RGB_G = 1;
            RGB_B = 1;
        end
        endcase
    end
endmodule