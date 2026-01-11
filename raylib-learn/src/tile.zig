const rl = @import("raylib");

const TILE_SIZE: usize = 80;
// Tile types:
// 0 = floor (passable)
// 1 = wall (solid)
// 2 = obstacle
const current_map = [_][10]u8{
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 0, 2, 2, 2, 0, 0, 0, 1 },
    .{ 1, 0, 0, 2, 2, 2, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
};

pub fn draw() void {
    for (0..current_map.len) |i| {
        for (0..current_map[i].len) |j| {
            const cell = current_map[i][j];
            const color: rl.Color = switch (cell) {
                1 => .yellow,
                2 => .brown,
                else => .black,
            };
            const x: i32 = @intCast(j * TILE_SIZE);
            const y: i32 = @intCast(i * TILE_SIZE);
            rl.drawRectangle(x, y, TILE_SIZE, TILE_SIZE, color);
        }
    }
}

const std = @import("std");

pub fn isSolid(x: f32, y: f32, worldWidth: f32, worldHeight: f32) bool {
    if (x < 0 or x >= worldWidth or y < 0 or y >= worldHeight) return true;
    //world boundary
    const tileSize: f32 = @floatFromInt(TILE_SIZE);
    const rawTileX = @floor(x / tileSize);
    const rawTileY = @floor(y / tileSize);
    // std.debug.print("pos: ({d}, {d}) -> tile: ({d}, {d})\n", .{ x, y, rawTileX, rawTileY });
    //
    const tileX: usize = @intFromFloat(rawTileX);
    const tileY: usize = @intFromFloat(rawTileY);

    return tileY >= current_map.len or tileX >= current_map[0].len or current_map[tileY][tileX] != 1;
}

// Call this in main after drawing tiles to see which tile is being checked
pub fn debugDrawTileAt(x: f32, y: f32) void {
    const tileSize: f32 = @floatFromInt(TILE_SIZE);
    const tileX: i32 = @intFromFloat(@floor(x / tileSize) * tileSize);
    const tileY: i32 = @intFromFloat(@floor(y / tileSize) * tileSize);
    // Draw red outline around the tile being checked
    rl.drawRectangleLines(tileX, tileY, TILE_SIZE, TILE_SIZE, .red);
    // Draw small circle at exact check position
    rl.drawCircle(@intFromFloat(x), @intFromFloat(y), 5, .red);
}
