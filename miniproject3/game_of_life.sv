
module game_of_life (
    input  logic clk,
    input  logic reset,
    input  logic advance,
    output logic [63:0] cells
);

    logic [7:0] current_grid [0:7];
    logic [7:0] next_grid [0:7];

    integer row, col;
    integer dr, dc;
    integer neighbor_row, neighbor_col;
    integer neighbor_count;

    // load the starting pattern directly into the grid
    initial begin
        $readmemh("initial_state.mem", current_grid);
    end

    // calculate the next generation
    always_comb begin
        for (integer r = 0; r < 8; r = r + 1)
            next_grid[r] = 8'b0;

        for (row = 0; row < 8; row = row + 1) begin
            for (col = 0; col < 8; col = col + 1) begin
                neighbor_count = 0;

                for (dr = -1; dr <= 1; dr = dr + 1) begin
                    for (dc = -1; dc <= 1; dc = dc + 1) begin
                        if (dr != 0 || dc != 0) begin
                            neighbor_row = (row + dr + 8) % 8;
                            neighbor_col = (col + dc + 8) % 8;

                            neighbor_count = neighbor_count +
                                current_grid[neighbor_row][neighbor_col];
                        end
                    end
                end

                if (current_grid[row][col]) begin
                    // A living cell survives with 2 or 3 neighbors
                    if (neighbor_count == 2 || neighbor_count == 3)
                        next_grid[row][col] = 1'b1;
                end else begin
                    // A dead cell becomes alive with exactly 3 neighbors
                    if (neighbor_count == 3)
                        next_grid[row][col] = 1'b1;
                end
            end
        end
    end

    // Reset restores the initial pattern; advance updates the grid
    always_ff @(posedge clk) begin
        if (reset) begin
            current_grid[0] <= 8'h00;
            current_grid[1] <= 8'h08;
            current_grid[2] <= 8'h10;
            current_grid[3] <= 8'h38;
            current_grid[4] <= 8'h00;
            current_grid[5] <= 8'h00;
            current_grid[6] <= 8'h00;
            current_grid[7] <= 8'h00;
        end else if (advance) begin
            for (integer i = 0; i < 8; i = i + 1)
                current_grid[i] <= next_grid[i];
        end
    end

    // Flatten the 8x8 grid into a 64-bit output
    always_comb begin
        for (integer r = 0; r < 8; r = r + 1)
            cells[r*8 +: 8] = current_grid[r];
    end

endmodule