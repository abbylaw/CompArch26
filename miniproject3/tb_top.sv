
`timescale 1ns / 1ps

module tb_top;
    logic clk = 0;
    logic reset = 1;
    logic advance = 0;
    logic [63:0] cells;

    integer errors = 0;

    game_of_life dut (
        .clk(clk),
        .reset(reset),
        .advance(advance),
        .cells(cells)
    );

    always #5 clk = ~clk;

    // print the 8x8 grid
    task print_grid;
        integer r, c;
        begin
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    if (cells[r*8+c] === 1'b1)
                        $write("O ");
                    else if (cells[r*8+c] === 1'b0)
                        $write(". ");
                    else
                        $write("? ");
                end
                $write("\n");
            end
        end
    endtask

    // clear the grid for a controlled rule test
    task clear_pattern;
        integer r;
        begin
            for (r = 0; r < 8; r = r + 1)
                dut.current_grid[r] = 8'b0;
        end
    endtask

    // check a cell in the calculated next generation
    task check_next;
        input integer r;
        input integer c;
        input expected;
        input [8*40-1:0] description;
        begin
            if (dut.next_grid[r][c] !== expected) begin
                $display("FAIL: %0s", description);
                $display("  Cell (%0d,%0d): expected %b, got %b",
                         r, c, expected, dut.next_grid[r][c]);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", description);
            end
        end
    endtask

    initial begin
        $dumpfile("game_of_life.vcd");
        $dumpvars(0, tb_top);

        // reset and show the original starting pattern
        repeat (2) @(negedge clk);
        reset = 0;

        #1;
        $display("\nInitial grid:");
        print_grid;

        // display 10 generations
        for (integer gen = 1; gen <= 10; gen = gen + 1) begin
            @(negedge clk);
            advance = 1;

            @(negedge clk);
            advance = 0;

            #1;
            $display("\nGeneration %0d:", gen);
            print_grid;
        end

        // test the rules using controlled patterns.
        // advance stays low so the sequential grid is not updated.

        $display("\n--- Game of Life Rule Tests ---");

        // 1. Survival: live cell with 2 neighbors survives
        clear_pattern;
        dut.current_grid[3][3] = 1'b1;
        dut.current_grid[3][2] = 1'b1;
        dut.current_grid[3][4] = 1'b1;
        #1;
        check_next(3, 3, 1'b1, "Survival with 2 neighbors");

        // 2. Underpopulation: live cell with 1 neighbor dies
        clear_pattern;
        dut.current_grid[3][3] = 1'b1;
        dut.current_grid[3][4] = 1'b1;
        #1;
        check_next(3, 3, 1'b0, "Death with fewer than 2 neighbors");

        // 3. Birth: dead cell with 3 neighbors becomes alive
        clear_pattern;
        dut.current_grid[3][2] = 1'b1;
        dut.current_grid[3][4] = 1'b1;
        dut.current_grid[2][3] = 1'b1;
        #1;
        check_next(3, 3, 1'b1, "Birth with exactly 3 neighbors");

        // 4. Overpopulation: live cell with 4 neighbors dies
        clear_pattern;
        dut.current_grid[3][3] = 1'b1;
        dut.current_grid[2][2] = 1'b1;
        dut.current_grid[2][3] = 1'b1;
        dut.current_grid[2][4] = 1'b1;
        dut.current_grid[3][2] = 1'b1;
        #1;
        check_next(3, 3, 1'b0, "Death with more than 3 neighbors");

        // 5. Wraparound: cell (0,0) has 3 neighbors across edges
        clear_pattern;
        dut.current_grid[7][7] = 1'b1;
        dut.current_grid[7][0] = 1'b1;
        dut.current_grid[0][7] = 1'b1;
        #1;
        check_next(0, 0, 1'b1, "Wraparound across grid edges");

        // Report test results
        $display("\n--- Test Summary ---");
        if (errors == 0)
            $display("ALL 5 RULE TESTS PASSED");
        else
            $display("%0d RULE TEST(S) FAILED", errors);

        $finish;
    end
endmodule
