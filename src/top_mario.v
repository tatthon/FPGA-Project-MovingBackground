`timescale 1ns / 1ps

// Moving background only: no Mario, no sprites, no sprite RAM.
// Compatible with the original Tiny Tapeout VGA pin assignment.
module tt_um_vga_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire hsync_raw, vsync_raw, display_on_raw;
    wire [9:0] pix_x, pix_y;

    hvsync_generator vga_sync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync_raw),
        .vsync(vsync_raw),
        .display_on(display_on_raw),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // Each frame, move the camera by one pixel; wrap at the end of
    // the 1280-pixel-wide map (visible screen width is 640 pixels).
    reg [9:0] scrollOffset;
    wire frame_tick = (pix_x == 10'd0) && (pix_y == 10'd480);
    always @(posedge clk) begin
        if (!rst_n)
            scrollOffset <= 10'd0;
        else if (frame_tick) begin
            if(ui_in[0] && !ui_in[1]) begin 
              scrollOffset <= (scrollOffset == 10'0)
                            ? 10'd0 : scrollOffset - 10'd1;
            end
            if(!ui_in[0] && ui_in[1]) begin 
              scrollOffset <= (scrollOffset == 10'd640)
                            ? 10'd640 : scrollOffset + 10'd1;
            end
        end
    end

    wire [10:0] x_scroll = {1'b0, pix_x} + {1'b0, scrollOffset};
    wire [5:0] bg_color;
    bg_renderer background (
        .clk(clk),
        .reset(~rst_n),
        .x_scroll(x_scroll),
        .y(pix_y),
        .color(bg_color)
    );

    // ROM pipeline delays RGB by 2 cycles compared with pixel coordinates.
    // VGA sync generator already registers sync once, so delay sync 1 more.
    reg active_d1, active_d2;
    reg hsync_d1, vsync_d1;
    always @(posedge clk) begin
        if (!rst_n) begin
            active_d1 <= 1'b0;
            active_d2 <= 1'b0;
            hsync_d1 <= 1'b1;
            vsync_d1 <= 1'b1;
        end else begin
            active_d1 <= display_on_raw;
            active_d2 <= active_d1;
            hsync_d1 <= hsync_raw;
            vsync_d1 <= vsync_raw;
        end
    end

    wire [1:0] R = active_d2 ? bg_color[5:4] : 2'b00;
    wire [1:0] G = active_d2 ? bg_color[3:2] : 2'b00;
    wire [1:0] B = active_d2 ? bg_color[1:0] : 2'b00;

    assign uo_out = {hsync_d1, B[0], G[0], R[0],
                     vsync_d1, B[1], G[1], R[1]};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
    wire _unused_ok = &{ena, ui_in, uio_in};
endmodule
