# Tile-Based Collision Detection

## Basic Concept

In tile-based games, the world is divided into a grid. Each tile has a type (floor, wall, etc.). Collision detection checks if the player's position overlaps with solid tiles.

## Converting World Position to Tile Index

```
tile_x = floor(world_x / TILE_SIZE)
tile_y = floor(world_y / TILE_SIZE)
```

Example with TILE_SIZE = 80:
```
World position (150, 200)
tile_x = floor(150 / 80) = floor(1.875) = 1
tile_y = floor(200 / 80) = floor(2.5) = 2
Result: Tile (1, 2)
```

## The Problem: Single Point Check

If you only check ONE point for collision, the player can clip through walls at corners.

```
Player (20x20) at position (160, 70) moving LEFT:

                x=80      x=160
                   │         │
       y=70  ──────┼─────────●─────────┐
                   │         │    P    │
       y=80  ──────┼─────────┼─────────┤
                   │  WALL   │         │
                   │         └─────────┘
       y=90        │
```

- Single point check at top-left (159, 70): CLEAR
- Movement allowed
- But bottom of player clips into wall!

## The Solution: Two-Point Check

Check BOTH corners of the leading edge when moving.

```
Player moving LEFT - check both left corners:

       ● ─────────┐        ● = check point 1 (top-left)
       │          │
       │    P     │
       │          │
       ● ─────────┘        ● = check point 2 (bottom-left)
```

Both points must be clear for movement to be allowed.

## Check Points Per Direction

For a character drawn from TOP-LEFT at position (x, y) with SIZE = 20:

```
(x, y) ─────────────── (x+20, y)
   │                      │
   │      Character       │
   │                      │
(x, y+20) ────────────── (x+20, y+20)
```

### Moving UP (W)
Check: top-left and top-right of NEW position
```zig
const new_y = pos.y - speed * dt;
check(pos.x, new_y)           // top-left
check(pos.x + SIZE - 1, new_y) // top-right
```

### Moving DOWN (S)
Check: bottom-left and bottom-right of NEW position
```zig
const new_y = pos.y + speed * dt;
check(pos.x, new_y + SIZE)           // bottom-left
check(pos.x + SIZE - 1, new_y + SIZE) // bottom-right
```

### Moving LEFT (A)
Check: top-left and bottom-left of NEW position
```zig
const new_x = pos.x - speed * dt;
check(new_x, pos.y)           // top-left
check(new_x, pos.y + SIZE - 1) // bottom-left
```

### Moving RIGHT (D)
Check: top-right and bottom-right of NEW position
```zig
const new_x = pos.x + speed * dt;
check(new_x + SIZE, pos.y)           // top-right
check(new_x + SIZE, pos.y + SIZE - 1) // bottom-right
```

## Visual Example: Why Bottom-Left Matters

```
Player at (160, 70), SIZE = 20
Wants to move LEFT to x = 159

       x=80      x=159    x=179
          │         │         │
y=70 ─────┼─────────●─────────┐    ● top-left (159, 70)
          │         │         │      → tile (1, 0) → CLEAR
          │         │    P    │
y=80 ─────┼─────────┼─────────┤
          │  WALL   │         │
          │  tile   └─────────┘
y=89      │  (1,1)  ●              ● bottom-left (159, 89)
          │         │                → tile (1, 1) → WALL!
```

- Top-left check: (159, 70) → tile (1, 0) → passable
- Bottom-left check: (159, 89) → tile (1, 1) → SOLID

Result: Movement BLOCKED (one point hit wall)

Without bottom-left check: player would move and clip into wall.

## Code Implementation

```zig
pub fn isSolid(x: f32, y: f32) bool {
    const tileSize: f32 = @floatFromInt(TILE_SIZE);
    const tileX: usize = @intFromFloat(@floor(x / tileSize));
    const tileY: usize = @intFromFloat(@floor(y / tileSize));
    return map[tileY][tileX] == WALL;
}

// Movement with two-point collision
if (rl.isKeyDown(.a)) { // LEFT
    const new_x = pos.x - speed * dt;
    const top_clear = !isSolid(new_x, pos.y);
    const bottom_clear = !isSolid(new_x, pos.y + SIZE - 1);

    if (top_clear and bottom_clear) {
        pos.x = new_x;
    }
}
```

## Why SIZE - 1?

Using `SIZE - 1` instead of `SIZE` keeps check points inside the character bounds:

```
SIZE = 20

With SIZE:     (0) ──────────────── (20)  ← point 20 is OUTSIDE
With SIZE-1:   (0) ──────────────── (19)  ← point 19 is INSIDE
```

This prevents false positives at tile boundaries.

## Common Mistakes

1. **Swapped X/Y**: Array is `[row][col]` = `[y][x]`, not `[x][y]`

2. **Wrong edge checked**:
   - LEFT movement checks LEFT edge (new_x)
   - RIGHT movement checks RIGHT edge (new_x + SIZE)

3. **Single point check**: Causes corner clipping

4. **Checking old position**: Always check the NEW position before moving

5. **Inverted solid logic**:
   ```zig
   // WRONG: returns true for passable
   return map[y][x] != WALL;

   // RIGHT: returns true for solid
   return map[y][x] == WALL;
   ```

## Advanced: Diagonal Movement

With separate `if` statements (not `else if`), diagonal movement works automatically:

```zig
if (rl.isKeyDown(.w)) { /* check and move Y */ }
if (rl.isKeyDown(.a)) { /* check and move X */ }
```

Pressing W+A moves diagonally. Each axis is checked independently.

## Summary

1. Convert world position to tile index: `floor(pos / TILE_SIZE)`
2. Check TWO points per direction (both corners of leading edge)
3. Only move if BOTH points are clear
4. Use `and` to combine checks: `!isSolid(p1) and !isSolid(p2)`
