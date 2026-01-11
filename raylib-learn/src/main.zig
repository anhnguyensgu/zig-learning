const std = @import("std");
const rl = @import("raylib");
const root = @import("raylib_learn");
const DebugDraw = root.DebugDraw;

const SPEED: f32 = 100;
const WORLD_WIDTH : f32 = 800;
const WORLD_HEIGHT : f32 = 800;

pub fn main() !void {
    const windowWidth = 400;
    const windowHeight = 800;
    rl.initWindow(windowWidth, windowHeight, "hello raylib");
    defer rl.closeWindow();

    rl.setWindowTitle("hello world");

    rl.setTargetFPS(60);

    var state = GameState{
        .chacter = Character{
            .pos = rl.Vector2{ .x = 0, .y = 0 },
        },
    };

    const player = state.chacter;
    const view_half_w: f32 = (@as(f32, @floatFromInt(rl.getScreenWidth())) * 0.5);
    const view_half_h: f32 = (@as(f32, @floatFromInt(rl.getScreenHeight())) * 0.5);
    var cam_target_x: f32 = player.pos.x + 20 * 0.5;
    var cam_target_y: f32 = player.pos.y + 20 * 0.5;
    var camera = rl.Camera2D{
        .target = state.chacter.pos,
        .offset = rl.Vector2{
            .x = view_half_w,
            .y = view_half_h,
        },
        .rotation = 0,
        .zoom = 1.0,
    };

    while (!rl.windowShouldClose()) {
        //set up
        const dt = rl.getFrameTime();

        handleMovement(&state.chacter, dt);

        cam_target_x = std.math.clamp(state.chacter.pos.x, camera.offset.x, 800 - camera.offset.x);
        cam_target_y = std.math.clamp(state.chacter.pos.y, camera.offset.y, 800 - camera.offset.y);
        camera.target = .init(cam_target_x, cam_target_y);

        // draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        {
            camera.begin();
            defer camera.end();
            root.tile.draw();
            // DebugDraw.drawGrid(.{ .spacing = 50 });
            // DebugDraw.drawAxes(.{ .origin = .{ .x = 0, .y = 0 }, .len = 200 });
            const top_left_world = rl.getScreenToWorld2D(.{ .x = 0, .y = 0 }, camera);
            DebugDraw.drawCoords(state.chacter.pos, .{ .x = top_left_world.x, .y = top_left_world.y });
            CharacterUI.draw(state.chacter.pos);
            // root.tile.debugDrawTileAt(chacterPos.x, chacterPos.y);
        }
    }
}

const GameState = struct {
    chacter: Character,
    level: i32 = 0,
};

const Character = struct {
    pos: rl.Vector2,
    const SIZE: f32 = 20;
};

// Movement with tile collision
// - pos: current position (top-left of character)
// - SIZE: character width/height (20x20)
// - Each direction checks TWO corners of the leading edge
// - Using `if` (not `else if`) allows diagonal movement (W+D, etc.)
// - Both corners must be clear for movement to be allowed
//
// DIAGONAL MOVEMENT (e.g., W + A = top-left):
// When both W and A are pressed in the same frame:
//   1. W runs first: checks top edge, updates Y if clear
//   2. A runs second: checks left edge, updates X if clear
//
// ●───────────● ← W checks top edge
// ●           │
// │     P     │
// ●───────────┘
// ↑ A checks left edge
//
// Each axis is independent - if top is blocked but left is clear,
// player slides along the wall horizontally (and vice versa).
fn handleMovement(character: *Character, dt: f32) void {
    const speed = if (rl.isKeyDown(.left_shift)) SPEED * 3 else SPEED;
    const pos = character.pos;
    const SIZE = Character.SIZE;

    // UP: check top edge (top-left and top-right corners)
    // ●───────────● ← check these two points
    // │           │
    // │     P     │
    // └───────────┘
    if (rl.isKeyDown(.w)) {
        const new_y = pos.y - speed * dt;
        if (!root.tile.isSolid(pos.x, new_y, WORLD_WIDTH, WORLD_HEIGHT) and !root.tile.isSolid(pos.x + SIZE - 1, new_y, WORLD_WIDTH, WORLD_HEIGHT)) {
            character.pos.y = new_y;
        }
    }

    // DOWN: check bottom edge (bottom-left and bottom-right corners)
    // ┌───────────┐
    // │     P     │
    // │           │
    // ●───────────● ← check these two points
    if (rl.isKeyDown(.s)) {
        const new_y = pos.y + speed * dt;
        if (!root.tile.isSolid(pos.x, new_y + SIZE, WORLD_WIDTH, WORLD_HEIGHT) and !root.tile.isSolid(pos.x + SIZE - 1, new_y + SIZE, WORLD_WIDTH, WORLD_HEIGHT)) {
            character.pos.y = new_y;
        }
    }

    // LEFT: check left edge (top-left and bottom-left corners)
    // ●───────────┐
    // │           │  ← check these
    // │     P     │    two points
    // ●───────────┘
    if (rl.isKeyDown(.a)) {
        const new_x = pos.x - speed * dt;
        if (!root.tile.isSolid(new_x, pos.y, WORLD_WIDTH, WORLD_HEIGHT) and !root.tile.isSolid(new_x, pos.y + SIZE - 1, WORLD_WIDTH, WORLD_HEIGHT)) {
            character.pos.x = new_x;
        }
    }

    // RIGHT: check right edge (top-right and bottom-right corners)
    // ┌───────────●
    // │           │  ← check these
    // │     P     │    two points
    // └───────────●
    if (rl.isKeyDown(.d)) {
        const new_x = pos.x + speed * dt;
        if (!root.tile.isSolid(new_x + SIZE, pos.y, WORLD_WIDTH, WORLD_HEIGHT) and !root.tile.isSolid(new_x + SIZE, pos.y + SIZE - 1, WORLD_WIDTH, WORLD_HEIGHT)) {
            character.pos.x = new_x;
        }
    }
}

const CharacterUI = struct {
    pub fn draw(pos: rl.Vector2) void {
        const x: i32 = @intFromFloat(pos.x);
        const y: i32 = @intFromFloat(pos.y);
        rl.drawRectangle(x, y, 20, 20, .dark_blue);
    }
};

