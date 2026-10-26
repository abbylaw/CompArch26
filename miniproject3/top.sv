
module top (
    input  logic clk,
    input  logic SW,
    input  logic BOOT,
    output logic _48b,
    output logic _45a
);

    logic [63:0] cells;
    logic reset;
    logic advance = 1'b0;

    // Advance the Game of Life once per second
    localparam integer GEN_INTERVAL = 12_000_000;
    logic [23:0] gen_counter = 24'd0;

    assign reset = ~BOOT;

    game_of_life life (
        .clk     (clk),
        .reset   (reset),
        .advance (advance),
        .cells   (cells)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            gen_counter <= 24'd0;
            advance <= 1'b0;
        end else if (gen_counter == GEN_INTERVAL - 1) begin
            gen_counter <= 24'd0;
            advance <= 1'b1;
        end else begin
            gen_counter <= gen_counter + 1'b1;
            advance <= 1'b0;
        end
    end

    // WS2812B LED controller signals
    logic [5:0] pixel;
    logic [4:0] frame;
    logic load_sreg;
    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;

    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;
    logic [23:0] shift_reg = 24'd0;

    // Hue color wheel
    // One hue step every 100,000 clock cycles
    localparam integer HUE_INTERVAL = 100_000;
    logic [16:0] hue_counter = 17'd0;
    logic [7:0] hue = 8'd0;

    logic [7:0] hue_offset;
    logic [7:0] ramp;
    logic [7:0] color_red;
    logic [7:0] color_green;
    logic [7:0] color_blue;

    always_ff @(posedge clk) begin
        if (reset) begin
            hue_counter <= 17'd0;
            hue <= 8'd0;
        end else if (hue_counter == HUE_INTERVAL - 1) begin
            hue_counter <= 17'd0;
            hue <= hue + 1'b1;
        end else begin
            hue_counter <= hue_counter + 1'b1;
        end
    end

    // Convert hue into RGB values.
    // Limit each channel to a maximum value of 32.
    always_comb begin
        hue_offset = 8'd0;
        ramp = 8'd0;
        color_red = 8'd0;
        color_green = 8'd0;
        color_blue = 8'd0;

        if (hue < 43) begin
            hue_offset = hue;
            ramp = hue_offset - (hue_offset >> 2);
            color_red = 8'd32;
            color_green = ramp;
        end else if (hue < 86) begin
            hue_offset = hue - 43;
            ramp = hue_offset - (hue_offset >> 2);
            color_red = 8'd32 - ramp;
            color_green = 8'd32;
        end else if (hue < 129) begin
            hue_offset = hue - 86;
            ramp = hue_offset - (hue_offset >> 2);
            color_green = 8'd32;
            color_blue = ramp;
        end else if (hue < 172) begin
            hue_offset = hue - 129;
            ramp = hue_offset - (hue_offset >> 2);
            color_green = 8'd32 - ramp;
            color_blue = 8'd32;
        end else if (hue < 215) begin
            hue_offset = hue - 172;
            ramp = hue_offset - (hue_offset >> 2);
            color_red = ramp;
            color_blue = 8'd32;
        end else begin
            hue_offset = hue - 215;
            ramp = hue_offset - (hue_offset >> 2);
            color_red = 8'd32;
            color_blue = 8'd32 - ramp;
        end
    end

    // Living cells use the current hue.
    // Dead cells remain black.
    always_comb begin
        red_data = 8'd0;
        green_data = 8'd0;
        blue_data = 8'd0;

        if (cells[pixel]) begin
            red_data = color_red;
            green_data = color_green;
            blue_data = color_blue;
        end
    end

    // Load the next pixel's color or shift out the current color.
    always_ff @(posedge clk) begin
        if (load_sreg) begin
            shift_reg <= {green_data, red_data, blue_data};
        end else if (shift) begin
            shift_reg <= {shift_reg[22:0], 1'b0};
        end
    end

    controller ctrl (
        .clk            (clk),
        .load_sreg      (load_sreg),
        .transmit_pixel (transmit_pixel),
        .pixel          (pixel),
        .frame          (frame)
    );

    ws2812b led_driver (
        .clk         (clk),
        .serial_in   (shift_reg[23]),
        .transmit    (transmit_pixel),
        .ws2812b_out (ws2812b_out),
        .shift       (shift)
    );

    assign _48b = ws2812b_out;
    assign _45a = ~ws2812b_out;

endmodule