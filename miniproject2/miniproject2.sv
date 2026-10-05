module top(
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

    // Timing parameters
    parameter COLOR_INTERVAL = 2000000;
    parameter INC_DEC_INTERVAL = 10000;
    parameter INC_DEC_MAX = 200;
    parameter PWM_INTERVAL = 1200;
    parameter INC_DEC_VAL = 6;


    // Define color states
    localparam RED_TO_YELLOW = 3'd0;
    localparam YELLOW_TO_GREEN = 3'd1;
    localparam GREEN_TO_CYAN = 3'd2;
    localparam CYAN_TO_BLUE = 3'd3;
    localparam BLUE_TO_MAGENTA = 3'd4;
    localparam MAGENTA_TO_RED = 3'd5;

    // Declare state and counter variables
    logic [2:0] color_state = RED_TO_YELLOW;

    logic [$clog2(INC_DEC_INTERVAL) - 1:0] count = 0;
    logic [$clog2(INC_DEC_MAX) - 1:0] inc_dec_count = 0;
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_count = 0;

    // Declare RGB brightness values
    logic [$clog2(PWM_INTERVAL + 1) - 1:0] pwm_red = PWM_INTERVAL;
    logic [$clog2(PWM_INTERVAL + 1) - 1:0] pwm_green = 0;
    logic [$clog2(PWM_INTERVAL + 1) - 1:0] pwm_blue = 0;

        // Update RGB brightness values
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL - 1) begin
            count <= 0;

            case (color_state)
                RED_TO_YELLOW:
                    pwm_green <= pwm_green + INC_DEC_VAL;

                YELLOW_TO_GREEN:
                    pwm_red <= pwm_red - INC_DEC_VAL;

                GREEN_TO_CYAN:
                    pwm_blue <= pwm_blue + INC_DEC_VAL;

                CYAN_TO_BLUE:
                    pwm_green <= pwm_green - INC_DEC_VAL;

                BLUE_TO_MAGENTA:
                    pwm_red <= pwm_red + INC_DEC_VAL;

                MAGENTA_TO_RED:
                    pwm_blue <= pwm_blue - INC_DEC_VAL;
            endcase
        end
        else begin
            count <= count + 1;
        end
    end

        // Track the number of brightness updates
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL - 1) begin
            if (inc_dec_count == INC_DEC_MAX - 1) begin
                inc_dec_count <= 0;

                if (color_state == MAGENTA_TO_RED)
                    color_state <= RED_TO_YELLOW;
                else
                    color_state <= color_state + 1;
            end
            else begin
                inc_dec_count <= inc_dec_count + 1;
            end
        end
    end

    // PWM counter
    always_ff @(posedge clk) begin
        if (pwm_count == PWM_INTERVAL - 1)
            pwm_count <= 0;
        else
            pwm_count <= pwm_count + 1;
    end

    // Active-low RGB outputs
    always_comb begin
        RGB_R = (pwm_count < pwm_red) ? 1'b0 : 1'b1;
        RGB_G = (pwm_count < pwm_green) ? 1'b0 : 1'b1;
        RGB_B = (pwm_count < pwm_blue) ? 1'b0 : 1'b1;
    end
    endmodule