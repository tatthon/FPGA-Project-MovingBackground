`timescale 1ns / 1ps

// Tile atlas: 256 tiles, each 16x16 pixels; RGB222 (6 bits/pixel).
// Timing: color corresponds to the supplied x/y after two rising edges.
module bg_renderer (
    input  wire        clk,
    input  wire        reset,
    input  wire [10:0] x_scroll,
    input  wire [9:0]  y,
    output reg  [5:0]  color
);
    reg [5:0] mem [0:65535];
    wire [7:0] tile;
    reg [3:0] pixel_x_d1, pixel_y_d1;
    wire [15:0] pixel_address = {tile[7:4], pixel_y_d1, tile[3:0], pixel_x_d1};

    initial begin
        $readmemh("../data/mariobg256j.mem", mem);
    end

    // First stage: synchronous tile ID lookup and local coordinates.
    map_rom tile_map (
        .clk(clk),
        .x_scroll(x_scroll[10:4]),
        .y(y),
        .tile(tile)
    );

    always @(posedge clk) begin
        if (reset) begin
            pixel_x_d1 <= 4'd0;
            pixel_y_d1 <= 4'd0;
            color <= 6'd0;
        end else begin
            pixel_x_d1 <= x_scroll[3:0];
            pixel_y_d1 <= y[3:0];
            // Second stage. Tile 0 is ordinary sky, NOT transparency.
            color <= mem[pixel_address];
        end
    end
endmodule
