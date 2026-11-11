# Moving Forest Background (VGA / Tiny Tapeout)

A Verilog-based **side-scrolling forest background** for a 640 × 480 VGA display. The design uses a tile map and an RGB222 tile atlas to draw sky, clouds, trees, bushes, and ground. This version renders **background only** — no Mario, character sprites, physics, or collisions.

## Features

- VGA output: **640 × 480**, nominal **60 Hz** with a **25.175 MHz** pixel clock.
- World background: **1280 × 480 pixels** (80 × 30 tiles).
- Each tile is **16 × 16 pixels**; atlas has **256 tiles**.
- Color format: **RGB222**, 2 bits per channel (6 bits per pixel).
- **Manual horizontal scrolling** via two active-high inputs.
- Camera stops at the left and right world boundaries.

## Controls

| Input | Function |
| --- | --- |
| `ui_in[0] = 1`, `ui_in[1] = 0` | Move camera left (scene shifts right) |
| `ui_in[0] = 0`, `ui_in[1] = 1` | Move camera right (scene shifts left) |
| Neither or both inputs asserted | Hold camera position |
| `rst_n = 0` | Reset camera to the left edge |

Scrolling changes the camera position **once per frame** (currently **2 pixels per frame**). Edit `SCROLL_STEP` in `src/top_mario.v` to change speed. Valid offsets are **0–640 pixels**: `1280 - 640 = 640`.

> Inputs are synchronized to the pixel clock but **not debounced**. A physical mechanical button may require external debounce logic.

## Project structure

```text
.
├── info.yaml
├── README.md
├── src/
│   ├── top_mario.v          # tt_um_vga_example top-level, controls and RGB outputs
│   ├── hsync_generator.v    # VGA counters and synchronization
│   ├── map_rom.v            # 80 × 30 tile-map ROM
│   └── bg_renderer.v        # 256-tile pixel atlas lookup
└── data/
    ├── map2.mem            # 2,400 tile IDs, 8-bit hexadecimal
    └── mariobg256j.mem     # 65,536 RGB222 pixels, 6-bit hexadecimal
```

Use the **latest cloud-corrected** `mariobg256j_cloud_fixed.mem` as `data/mariobg256j.mem` so cloud/tree backgrounds match the sky. Keep `map2.mem` as-is.

## How it works

1. `hvsync_generator` produces screen coordinates `pix_x`, `pix_y`, and VGA sync signals.
2. The top module computes the world X coordinate: `x_scroll = pix_x + scrollOffset`.
3. `map_rom` looks up the tile ID for the world position in `map2.mem`.
4. `bg_renderer` uses the tile ID and local coordinates within the 16 × 16 tile to look up RGB222 from `mariobg256j.mem`.
5. The top module aligns sync/display signals to the **two-clock renderer pipeline** and drives VGA RGB outputs.

The atlas is stored in **tile-major** order. Within each tile, pixels follow row-major order. The renderer computes:

```verilog
pixel_address = {tile[7:4], pixel_y_d1, tile[3:0], pixel_x_d1};
```

Tile ID `00` is an ordinary sky tile, **not transparency**. Blank areas should be filled with the sky tile in `map2.mem`; VGA blanking uses black output.

## VGA pinout (Tiny Tapeout)

| Output | Signal | Output | Signal |
| --- | --- | --- | --- |
| `uo_out[0]` | R1 | `uo_out[4]` | R0 |
| `uo_out[1]` | G1 | `uo_out[5]` | G0 |
| `uo_out[2]` | B1 | `uo_out[6]` | B0 |
| `uo_out[3]` | VSync | `uo_out[7]` | HSync |

The top module is `tt_um_vga_example`. `uio_out` and `uio_oe` are tied low; `uio_in` is unused. Use an external compatible VGA output circuit/board — these are digital GPIO signals, not direct VGA analog voltages.

## ROM file paths and simulation

Both ROMs use `$readmemh`:

```verilog
$readmemh("../data/map2.mem", mem);
$readmemh("../data/mariobg256j.mem", mem);
```

These paths are resolved relative to the **simulator's current working directory**, not automatically relative to the `.v` file. For the layout above, run the simulator from `src/`, or adjust the paths to match your simulation/build tool.

For example, with Icarus Verilog installed:

```bash
cd src
iverilog -g2012 -s tt_um_vga_example -o sim.vvp \
  top_mario.v hsync_generator.v map_rom.v bg_renderer.v
```

This command only **compiles** the design. To exercise the inputs and inspect VGA timing/image output, run it using an appropriate testbench (not included in this minimal project).

## Tiny Tapeout implementation note

`info.yaml` lists the four source files and requests `tiles: "1x1"`, but this is **not a verified fit**. The atlas alone contains `65,536 × 6 = 393,216` bits; the tile map adds `2,400 × 8 = 19,200` bits. Together that is **412,416 ROM bits** before implementation overhead, likely far beyond a 1×1 Tiny Tapeout tile if mapped into standard cells.

**Simulation using `$readmemh` does not prove ASIC synthesizability or area feasibility.** Before a tapeout, check the synthesis flow's treatment of ROM initialization and optimize/reduce the stored image data or choose suitable memory resources.

## Current limitations

- No character sprites, jumping, physics, collisions, or vertical scrolling.
- At the right edge, the scene stops; it does not wrap seamlessly.
- Button presses update camera position at frame boundaries (not instantaneously each clock cycle).
- RTL was prepared for the described project; **a full simulator and ASIC synthesis verification has not been completed**.

## License

No license is specified in this repository. Add a `LICENSE` file if you plan to distribute the project under an open-source license.
