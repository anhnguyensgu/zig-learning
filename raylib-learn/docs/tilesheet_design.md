# Tilesheet Design

## What is a Tilesheet?

A tilesheet (or spritesheet) is a single image containing multiple tiles arranged in a grid. Instead of loading many small images, you load one image and draw portions of it.

```
┌────┬────┬────┬────┐
│ 0  │ 1  │ 2  │ 3  │   ← tile indices
├────┼────┼────┼────┤
│ 4  │ 5  │ 6  │ 7  │
├────┼────┼────┼────┤
│ 8  │ 9  │ 10 │ 11 │
└────┴────┴────┴────┘
     tilesheet.png
```

## Benefits

- **Performance**: One texture load instead of many
- **Memory**: GPU handles one texture more efficiently
- **Organization**: All tiles in one file
- **Batch rendering**: Draw many tiles in fewer draw calls

## Your Tilesheet Layout

This describes the layout of your tileset image:

```
┌──┐ ┌──┐ ┌──┐ ┌──┐ ...  (12 tiles per row)
│  │ │  │ │  │ │  │
└──┘ └──┘ └──┘ └──┘
 ↑    ↑
 │    1px gap (spacing)
 │
 16px tile

┌──┐ ┌──┐ ┌──┐ ┌──┐ ...
│  │ │  │ │  │ │  │
└──┘ └──┘ └──┘ └──┘

... (11 rows total)
```

### Key info:

| Property | Value |
|----------|-------|
| Tile size | 16x16 pixels |
| Spacing | 1px gap between tiles |
| Columns | 12 tiles |
| Rows | 11 tiles |
| Total | 132 tiles |

### Important for code:

The **1px spacing** changes the math. Without spacing:
```
source_x = tile_index % 12 * 16
```

With 1px spacing:
```
source_x = tile_index % 12 * (16 + 1)  // 17px stride
```

### Your tileset image dimensions:

```
width  = 12 * 16 + 11 * 1 = 192 + 11 = 203px
height = 11 * 16 + 10 * 1 = 176 + 10 = 186px
```

## Tilesheet Properties

### 1. Tile Size
The width and height of each tile in pixels.

Common sizes:
- 8x8 - retro/pixel art
- 16x16 - classic RPG style
- 32x32 - modern pixel art
- 64x64 - detailed tiles

### 2. Spacing (Padding)
Gap between tiles to prevent texture bleeding.

```
No spacing:          With 1px spacing:
┌──┬──┬──┐           ┌──┐ ┌──┐ ┌──┐
│  │  │  │           │  │ │  │ │  │
├──┼──┼──┤           └──┘ └──┘ └──┘
│  │  │  │                ↑
└──┴──┴──┘           1px gap
```

### 3. Margin
Empty space around the entire tilesheet edge.

```
┌─────────────────┐
│  ┌──┬──┬──┐     │  ← margin
│  │  │  │  │     │
│  └──┴──┴──┘     │
└─────────────────┘
```

## Calculating Source Rectangle

To draw a specific tile, calculate its position in the tilesheet.

### Without Spacing

```
tile_index = 7
columns = 4
tile_size = 32

tile_x = index % columns = 7 % 4 = 3
tile_y = index / columns = 7 / 4 = 1

source_rect:
  x = tile_x * tile_size = 3 * 32 = 96
  y = tile_y * tile_size = 1 * 32 = 32
  width = 32
  height = 32
```

### With Spacing

```
tile_index = 7
columns = 4
tile_size = 16
spacing = 1

tile_x = index % columns = 7 % 4 = 3
tile_y = index / columns = 7 / 4 = 1

stride = tile_size + spacing = 17

source_rect:
  x = tile_x * stride = 3 * 17 = 51
  y = tile_y * stride = 1 * 17 = 17
  width = 16
  height = 16
```

### With Margin and Spacing

```
tile_index = 7
columns = 4
tile_size = 16
spacing = 1
margin = 2

tile_x = index % columns = 3
tile_y = index / columns = 1

stride = tile_size + spacing = 17

source_rect:
  x = margin + tile_x * stride = 2 + 3 * 17 = 53
  y = margin + tile_y * stride = 2 + 1 * 17 = 19
  width = 16
  height = 16
```

## Example: Getting Tile 25 from Your Tilesheet

```
tile_index = 25
columns = 12
tile_size = 16
spacing = 1

tile_x = 25 % 12 = 1
tile_y = 25 / 12 = 2

stride = 16 + 1 = 17

source_rect:
  x = 1 * 17 = 17
  y = 2 * 17 = 34
  width = 16
  height = 16
```

## Code Implementation

### Zig/Raylib Example

```zig
const Tilesheet = struct {
    texture: rl.Texture2D,
    tile_size: i32,
    spacing: i32,
    columns: i32,

    pub fn load(path: [*:0]const u8, tile_size: i32, spacing: i32, columns: i32) Tilesheet {
        return .{
            .texture = rl.loadTexture(path),
            .tile_size = tile_size,
            .spacing = spacing,
            .columns = columns,
        };
    }

    pub fn unload(self: *Tilesheet) void {
        rl.unloadTexture(self.texture);
    }

    pub fn getSourceRect(self: Tilesheet, tile_index: i32) rl.Rectangle {
        const tile_x = @mod(tile_index, self.columns);
        const tile_y = @divFloor(tile_index, self.columns);
        const stride = self.tile_size + self.spacing;

        return .{
            .x = @floatFromInt(tile_x * stride),
            .y = @floatFromInt(tile_y * stride),
            .width = @floatFromInt(self.tile_size),
            .height = @floatFromInt(self.tile_size),
        };
    }

    pub fn drawTile(self: Tilesheet, tile_index: i32, dest_x: i32, dest_y: i32) void {
        const source = self.getSourceRect(tile_index);
        const dest = rl.Vector2{
            .x = @floatFromInt(dest_x),
            .y = @floatFromInt(dest_y)
        };
        rl.drawTextureRec(self.texture, source, dest, rl.Color.white);
    }
};
```

### Usage

```zig
// Load tilesheet
var tilesheet = Tilesheet.load("assets/tilesheet.png", 16, 1, 12);
defer tilesheet.unload();

// Draw tile index 25 at position (100, 200)
tilesheet.drawTile(25, 100, 200);

// Draw map
for (map, 0..) |row, y| {
    for (row, 0..) |tile_index, x| {
        tilesheet.drawTile(
            tile_index,
            @intCast(x * 16),  // dest x (use tile_size for spacing on screen)
            @intCast(y * 16),  // dest y
        );
    }
}
```

## Common Mistakes

1. **Forgetting spacing in calculations**
   - Tiles appear offset or wrong tile shows

2. **Using wrong tile size**
   - Part of adjacent tile bleeds into view

3. **Integer vs float confusion**
   - Source rectangles need floats in raylib

4. **Off-by-one in spacing calculation**
   - `(columns - 1) * spacing` not `columns * spacing`

## Tools for Creating Tilesheets

- **Aseprite** - Pixel art editor with tilesheet export
- **Tiled** - Map editor that works with tilesheets
- **TexturePacker** - Automated spritesheet packing
- **Piskel** - Free online pixel art tool
- **GIMP** - Free image editor

## Resources

- [OpenGameArt.org](https://opengameart.org) - Free game assets
- [itch.io](https://itch.io/game-assets/free/tag-tileset) - Free tileset packs
- [Kenney.nl](https://kenney.nl/assets) - High quality free assets
