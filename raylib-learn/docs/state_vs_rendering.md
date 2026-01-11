# State vs Rendering Separation

## The Problem

A player character has:
- Movement state (walking, running, idle)
- Direction (up, down, left, right)
- Animation frame

How do we split this between core logic and rendering?

## Principle

```
┌─────────────────────────────────────────────────┐
│  Core (State)            │  Client (Render)     │
├──────────────────────────┼──────────────────────┤
│  Player.direction        │  Which sprite row    │
│  Player.velocity         │  Animation speed     │
│  Player.state (idle/run) │  Which animation     │
│  Player.anim_frame       │  Which sprite column │
└──────────────────────────┴──────────────────────┘
```

**Core** owns the state (what is happening).
**Client** interprets state for display (how it looks).

---

## Implementation

### Core: Player State (no raylib)

```zig
// game/player.zig
pub const Direction = enum { up, down, left, right };
pub const State = enum { idle, walking, running, attacking };

pub const Player = struct {
    pos: Vec2,
    velocity: Vec2,
    direction: Direction,
    state: State,
    anim_timer: f32,
    anim_frame: u32,

    pub fn update(self: *Player, input: InputState, dt: f32) void {
        // Update state based on input
        if (input.moving) {
            self.state = if (input.sprint) .running else .walking;
            self.direction = input.direction;
        } else {
            self.state = .idle;
        }

        // Update animation timer
        self.anim_timer += dt;
        const frame_duration = switch (self.state) {
            .idle => 0.2,
            .walking => 0.1,
            .running => 0.05,
            .attacking => 0.08,
        };

        if (self.anim_timer >= frame_duration) {
            self.anim_timer = 0;
            self.anim_frame = (self.anim_frame + 1) % self.getFrameCount();
        }
    }

    fn getFrameCount(self: Player) u32 {
        return switch (self.state) {
            .idle => 4,
            .walking => 6,
            .running => 6,
            .attacking => 4,
        };
    }
};
```

**Key points:**
- No raylib imports
- Only data and logic
- Can run on server or in tests

---

### Client: Player Renderer (uses raylib)

```zig
// client/player_renderer.zig
const Player = @import("../game/player.zig").Player;

pub const PlayerRenderer = struct {
    sheet: *SpriteSheet,

    pub fn draw(self: PlayerRenderer, player: *const Player) void {
        // Map state + direction to sprite index
        const row = self.getRow(player.state, player.direction);
        const col = player.anim_frame;
        const sprite_index = row * self.sheet.columns + col;

        const x: i32 = @intFromFloat(player.pos.x);
        const y: i32 = @intFromFloat(player.pos.y);

        self.sheet.draw(sprite_index, x, y);
    }

    fn getRow(self: PlayerRenderer, state: Player.State, dir: Player.Direction) u32 {
        _ = self;
        // Spritesheet layout:
        // Row 0-3: idle (up, down, left, right)
        // Row 4-7: walk (up, down, left, right)
        // Row 8-11: run (up, down, left, right)
        const base_row: u32 = switch (state) {
            .idle => 0,
            .walking => 4,
            .running => 8,
            .attacking => 12,
        };

        const dir_offset: u32 = switch (dir) {
            .down => 0,
            .up => 1,
            .left => 2,
            .right => 3,
        };

        return base_row + dir_offset;
    }
};
```

**Key points:**
- Takes Player as read-only input
- Maps state → sprite coordinates
- Only knows how to draw, not game logic

---

### Usage in GameState

```zig
// scenes/game.zig
const GameState = struct {
    player: Player,
    player_renderer: PlayerRenderer,

    pub fn init(assets: *Assets) GameState {
        return .{
            .player = Player.init(),
            .player_renderer = .{ .sheet = assets.chars.getPtr(.player) },
        };
    }

    pub fn update(self: *GameState, input: Input, dt: f32) void {
        self.player.update(input.toState(), dt);  // Core logic only
    }

    pub fn draw(self: *GameState) void {
        self.player_renderer.draw(&self.player);  // Rendering only
    }
};
```

---

## Spritesheet Layout

```
         Col 0   Col 1   Col 2   Col 3   Col 4   Col 5
        ┌───────┬───────┬───────┬───────┬───────┬───────┐
Row 0   │ idle  │ idle  │ idle  │ idle  │       │       │  ← down
Row 1   │ idle  │ idle  │ idle  │ idle  │       │       │  ← up
Row 2   │ idle  │ idle  │ idle  │ idle  │       │       │  ← left
Row 3   │ idle  │ idle  │ idle  │ idle  │       │       │  ← right
        ├───────┼───────┼───────┼───────┼───────┼───────┤
Row 4   │ walk  │ walk  │ walk  │ walk  │ walk  │ walk  │  ← down
Row 5   │ walk  │ walk  │ walk  │ walk  │ walk  │ walk  │  ← up
Row 6   │ walk  │ walk  │ walk  │ walk  │ walk  │ walk  │  ← left
Row 7   │ walk  │ walk  │ walk  │ walk  │ walk  │ walk  │  ← right
        ├───────┼───────┼───────┼───────┼───────┼───────┤
Row 8   │ run   │ run   │ run   │ run   │ run   │ run   │  ← down
Row 9   │ run   │ run   │ run   │ run   │ run   │ run   │  ← up
Row 10  │ run   │ run   │ run   │ run   │ run   │ run   │  ← left
Row 11  │ run   │ run   │ run   │ run   │ run   │ run   │  ← right
        └───────┴───────┴───────┴───────┴───────┴───────┘

Formula:
  sprite_index = (base_row + direction_offset) * columns + anim_frame
```

---

## Mapping Table

| State | Direction | Base Row | Dir Offset | Final Row |
|-------|-----------|----------|------------|-----------|
| idle | down | 0 | 0 | 0 |
| idle | up | 0 | 1 | 1 |
| idle | left | 0 | 2 | 2 |
| idle | right | 0 | 3 | 3 |
| walking | down | 4 | 0 | 4 |
| walking | up | 4 | 1 | 5 |
| walking | left | 4 | 2 | 6 |
| walking | right | 4 | 3 | 7 |
| running | down | 8 | 0 | 8 |
| running | up | 8 | 1 | 9 |
| ... | ... | ... | ... | ... |

---

## Responsibility Summary

| Layer | Knows About | Does NOT Know |
|-------|-------------|---------------|
| Player (core) | State, direction, frame index | Sprites, raylib, how to draw |
| Renderer (client) | How to map state → sprite | Game logic, input handling |

---

## Benefits

### 1. Testable Core Logic

```zig
test "player animation cycles" {
    var player = Player.init();
    player.state = .walking;

    // Simulate 10 frames
    for (0..10) |_| {
        player.update(.{}, 0.1);
    }

    // Frame should have cycled
    try std.testing.expect(player.anim_frame < 6);
}
```

No graphics needed for testing.

### 2. Swappable Renderer

```zig
// 2D renderer
const Renderer2D = struct {
    pub fn draw(self: Renderer2D, player: *const Player) void {
        // Draw sprite
    }
};

// 3D renderer (future)
const Renderer3D = struct {
    pub fn draw(self: Renderer3D, player: *const Player) void {
        // Draw 3D model with animation
    }
};
```

Same Player, different visuals.

### 3. Multiplayer Ready

```zig
// Server: runs Player.update() only
// Client: runs Player.update() + PlayerRenderer.draw()

// Server sends state:
const PlayerNetState = struct {
    pos: Vec2,
    direction: Direction,
    state: State,
    anim_frame: u32,
};
```

Core logic can run on server without raylib.

---

## Alternative: Animation Component

If many entities share animation logic, extract it:

```zig
// Reusable animation state
pub const Animation = struct {
    frame: u32,
    timer: f32,
    frame_count: u32,
    frame_duration: f32,

    pub fn update(self: *Animation, dt: f32) void {
        self.timer += dt;
        if (self.timer >= self.frame_duration) {
            self.timer = 0;
            self.frame = (self.frame + 1) % self.frame_count;
        }
    }

    pub fn reset(self: *Animation) void {
        self.frame = 0;
        self.timer = 0;
    }
};

// Player uses Animation
pub const Player = struct {
    pos: Vec2,
    direction: Direction,
    state: State,
    anim: Animation,

    pub fn update(self: *Player, input: InputState, dt: f32) void {
        const old_state = self.state;

        // Update state...

        // Reset animation on state change
        if (self.state != old_state) {
            self.anim = self.getAnimationFor(self.state);
        }

        self.anim.update(dt);
    }

    fn getAnimationFor(self: Player, state: State) Animation {
        _ = self;
        return switch (state) {
            .idle => .{ .frame = 0, .timer = 0, .frame_count = 4, .frame_duration = 0.2 },
            .walking => .{ .frame = 0, .timer = 0, .frame_count = 6, .frame_duration = 0.1 },
            .running => .{ .frame = 0, .timer = 0, .frame_count = 6, .frame_duration = 0.05 },
            .attacking => .{ .frame = 0, .timer = 0, .frame_count = 4, .frame_duration = 0.08 },
        };
    }
};
```

Now `Animation` can be reused by Enemy, NPC, etc.

---

## Summary

1. **Core** holds state (direction, animation frame, movement state)
2. **Renderer** maps state to visuals (which sprite to draw)
3. Core has no raylib dependency
4. Renderer only reads state, doesn't modify it
5. This enables testing, swappable renderers, and multiplayer
