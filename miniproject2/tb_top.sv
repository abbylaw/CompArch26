`timescale 1ns / 1ps

module tb_top;

    logic clk = 0;
    logic RGB_R;
    logic RGB_G;
    logic RGB_B;

    // Instantiate the design using its actual parameters
    top dut (
        .clk(clk),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    // Generate a clock with a 10 ns period
    always #41.6667 clk = ~clk;
    initial begin
        // Create a separate VCD file for the full simulation
        $dumpfile("mp2_full.vcd");

        // Record the signals we need to examine
        $dumpvars(0, dut.color_state);
        $dumpvars(0, dut.pwm_red);
        $dumpvars(0, dut.pwm_green);
        $dumpvars(0, dut.pwm_blue);
        $dumpvars(0, RGB_R);
        $dumpvars(0, RGB_G);
        $dumpvars(0, RGB_B);

        // Run long enough for one complete color cycle
        #1000000000;

        $finish;
    end

endmodule