Moving Background demo (Tiny Tapeout VGA, RGB222)

Files:
  src/top_mario.v         Top module tt_um_vga_example
  src/bg_renderer.v       Two-clock tile + pixel color renderer
  src/map_rom.v           Synchronous 80 x 30 tile map
  src/hsync_generator.v   VGA timing from original project
  data/map2.mem           2,400 tile IDs (80 x 30)
  data/mariobg256j.mem    65,536 RGB222 pixel colors (256 x 256 atlas)

NOTE ABOUT ROM PATHS:
  The $readmemh paths are ../data/... (same convention as original code).
  Run the simulator with working directory set to src/, or change both
  paths to data/... if running from the project root.

VGA input clock: 25.175 MHz nominal, 640 x 480 @ ~60 Hz.
Screen shows an auto-scrolling background with no sprite overlay.
Offset cycles from 0 through 640, advancing 1 pixel per frame.
The map is 80 x 30 tiles, each 16 x 16 pixels => 1280 x 480.

Pixel pipeline is two clock cycles. Sync and display active are delayed
in top_mario.v to match the color data.
