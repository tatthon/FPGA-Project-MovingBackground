`timescale 1ns / 1ps

// 80 columns x 30 rows of tile IDs (16x16 pixels per tile).
// x_scroll is the WORLD X coordinate in tile units.
module map_rom (
    input  wire       clk,
    input  wire [6:0] x_scroll,
    input  wire [9:0] y,
    output reg  [7:0] tile
);
    reg [7:0] mem [0:2399];
    wire valid = (x_scroll < 7'd80) && (y < 10'd480);
    wire [11:0] mem_index = ({5'd0, y[8:4]} * 12'd80) + {5'd0, x_scroll};

    initial begin
        $readmemh("../data/map2.mem", mem);
    end

    always @(posedge clk) begin
        tile <= valid ? mem[mem_index] : 8'h00;
    end
endmodule
