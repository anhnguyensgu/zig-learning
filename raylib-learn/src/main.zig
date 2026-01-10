const std = @import("std");
const rl = @import("raylib");
const root = @import("raylib_learn");

pub fn main() !void {
    rl.initWindow(800, 800, "hello raylib");
    defer rl.closeWindow();

    rl.setWindowTitle("hello world");

    rl.setTargetFPS(60);
    var state = GameState{
        .chacter = Character{
            .pos = rl.Vector2{ .x = 100, .y = 100 },
        },
    };

    const SPEED: f32 = 100;

    var camera = rl.Camera2D{
        .offset = rl.Vector2{
            .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
            .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0,
        },
        .target = state.chacter.pos,
        .rotation = 0,
        .zoom = 1.0,
    };

    while (!rl.windowShouldClose()) {
        //set up
        const dt = rl.getFrameTime();
        const speed = if (rl.isKeyDown(.left_shift))
            300
        else
            SPEED;

        if (rl.isKeyDown(.w)) {
            state.chacter.pos.y -= speed * dt;
        } else if (rl.isKeyDown(.s)) {
            state.chacter.pos.y += speed * dt;
        } else if (rl.isKeyDown(.d)) {
            state.chacter.pos.x += speed * dt;
        } else if (rl.isKeyDown(.a)) {
            state.chacter.pos.x -= speed * dt;
        }

        camera.target = state.chacter.pos;
        //for resizable window
        camera.offset = rl.Vector2{
            .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / 2.0,
            .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / 2.0,
        };

        // draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);
        {
            camera.begin();
            defer camera.end();
            DebugDraw.drawGrid(.{ .spacing = 50 });
            DebugDraw.drawAxes(.{ .origin = .{ .x = 0, .y = 0 }, .len = 200 });
            const top_left_world = rl.getScreenToWorld2D(.{ .x = 0, .y = 0 }, camera);
            DebugDraw.drawCoords(state.chacter.pos, .{ .x = top_left_world.x, .y = top_left_world.y });
            CharacterUI.draw(state.chacter.pos);
        }
    }
}

const GameState = struct {
    chacter: Character,
    level: i32 = 0,
};

const Character = struct {
    pos: rl.Vector2,
};

const CharacterUI = struct {
    pub fn draw(pos: rl.Vector2) void {
        const x: i32 = @intFromFloat(pos.x);
        const y: i32 = @intFromFloat(pos.y);
        rl.drawRectangle(x, y, 20, 20, .dark_blue);
    }
};

const DebugDraw = struct {
    const AxesOpts = struct {
        origin: rl.Vector2 = .{ .x = 0, .y = 0 },
        len: i32 = 200,
    };

    const GridOpts = struct {
        spacing: i32 = 50,
    };

    pub fn drawAxes(opts: AxesOpts) void {
        const ox: i32 = @intFromFloat(opts.origin.x);
        const oy: i32 = @intFromFloat(opts.origin.y);

        // X axis (right is +X)
        rl.drawLine(ox, oy, ox + opts.len, oy, .red);
        rl.drawText("+X", ox + opts.len + 6, oy - 8, 16, .red);

        // Y axis (down is +Y in raylib screen coords)
        rl.drawLine(ox, oy, ox, oy + opts.len, .green);
        rl.drawText("+Y", ox - 4, oy + opts.len + 6, 16, .green);

        // origin marker
        rl.drawCircle(ox, oy, 4, .black);
        rl.drawText("(0,0)", ox + 8, oy + 8, 16, .black);
    }

    pub fn drawGrid(opts: GridOpts) void {
        const w: i32 = rl.getScreenWidth();
        const h: i32 = rl.getScreenHeight();
        const s: i32 = @max(5, opts.spacing);

        var x: i32 = 0;
        while (x <= w) : (x += s) {
            rl.drawLine(x, 0, x, h, rl.Color{ .r = 220, .g = 220, .b = 220, .a = 255 });
            if (x != 0) rl.drawText(rl.textFormat("%d", .{x}), x + 2, 2, 12, .gray);
        }

        var y: i32 = 0;
        while (y <= h) : (y += s) {
            rl.drawLine(0, y, w, y, rl.Color{ .r = 220, .g = 220, .b = 220, .a = 255 });
            if (y != 0) rl.drawText(rl.textFormat("%d", .{y}), 2, y + 2, 12, .gray);
        }
    }

    pub fn drawCoords(player_pos: rl.Vector2, pos: rl.Vector2) void {
        const posx: i32 = @intFromFloat(pos.x);
        const posy: i32 = @intFromFloat(pos.y);
        const mouse = rl.getMousePosition();
        rl.drawText(rl.textFormat("mouse: (%.1f, %.1f)", .{ mouse.x, mouse.y }), posx, posy, 18, .black);
        rl.drawText(rl.textFormat("player: (%.1f, %.1f)", .{ player_pos.x, player_pos.y }), posx, posy + 20, 18, .dark_blue);
    }
};
