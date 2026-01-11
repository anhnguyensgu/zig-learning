# Asset Management Design in Zig

## The Problem

Games need multiple spritesheets:
- Tiles (dungeon, forest, castle)
- UI (buttons, panels, icons, inventory)
- Characters (player, enemies)
- Effects (particles, explosions)

How do we organize and access them with **minimal cost of change**?

## Design Goals

1. **Type-safe** - Compiler catches typos
2. **Fast lookup** - O(1) access
3. **Low cost to add** - Adding new asset shouldn't require changes everywhere
4. **Low cost to remove** - Compiler should find all usages
5. **Organized** - Easy to find and understand

## Options Comparison

### Option 1: Single Enum

```zig
const SpriteSheetId = enum {
    tiles_dungeon,
    tiles_forest,
    ui_button,
    ui_panel,
    player,
    enemy,
};

const Assets = struct {
    sheets: std.EnumArray(SpriteSheetId, SpriteSheet),

    pub fn get(self: *Assets, id: SpriteSheetId) *SpriteSheet {
        return self.sheets.getPtr(id);
    }
};

// Usage
assets.get(.tiles_dungeon).draw(5, x, y);
assets.get(.ui_button).draw(0, x, y);
```

**Pros:**
- Simple
- Single source of truth
- Compiler-checked

**Cons:**
- Gets messy with 30+ assets
- No logical grouping
- All assets in one place

---

### Option 2: Categorized Enums (Recommended)

```zig
const TileSheetId = enum { dungeon, forest, castle };
const UISheetId = enum { button, panel, icons, inventory };
const CharSheetId = enum { player, enemy_goblin, enemy_orc };

const Assets = struct {
    tiles: std.EnumArray(TileSheetId, SpriteSheet),
    ui: std.EnumArray(UISheetId, SpriteSheet),
    chars: std.EnumArray(CharSheetId, SpriteSheet),

    pub fn init() Assets {
        var self: Assets = undefined;

        // Tiles
        self.tiles.set(.dungeon, SpriteSheet.init("tiles/dungeon.png", 16, 16, 1, 12));
        self.tiles.set(.forest, SpriteSheet.init("tiles/forest.png", 16, 16, 1, 12));
        self.tiles.set(.castle, SpriteSheet.init("tiles/castle.png", 16, 16, 1, 12));

        // UI
        self.ui.set(.button, SpriteSheet.init("ui/button.png", 32, 32, 0, 4));
        self.ui.set(.panel, SpriteSheet.init("ui/panel.png", 64, 64, 0, 2));

        // Characters
        self.chars.set(.player, SpriteSheet.init("chars/player.png", 32, 32, 0, 8));

        return self;
    }

    pub fn deinit(self: *Assets) void {
        for (&self.tiles.values) |*s| s.deinit();
        for (&self.ui.values) |*s| s.deinit();
        for (&self.chars.values) |*s| s.deinit();
    }
};

// Usage
assets.tiles.get(.dungeon).draw(5, x, y);
assets.ui.get(.button).draw(0, x, y);
assets.chars.get(.player).draw(0, x, y);
```

**Pros:**
- Organized by category
- Scoped changes (UI changes don't touch tile code)
- Still compiler-checked
- Scales to ~100 assets

**Cons:**
- More structs to manage
- 2 places to modify when adding

---

### Option 3: HashMap (Dynamic)

```zig
const Assets = struct {
    sheets: std.StringHashMap(SpriteSheet),
    allocator: std.mem.Allocator,

    pub fn load(self: *Assets, name: []const u8, path: [*:0]const u8, ...) !void {
        const sheet = SpriteSheet.init(path, ...);
        try self.sheets.put(name, sheet);
    }

    pub fn get(self: *Assets, name: []const u8) ?*SpriteSheet {
        return self.sheets.getPtr(name);
    }
};

// Usage
try assets.load("tiles_dungeon", "tiles/dungeon.png", 16, 16, 1, 12);
assets.get("tiles_dungeon").?.draw(5, x, y);
```

**Pros:**
- Dynamic loading/unloading
- Single place to add (just call load)
- Good for level-specific assets

**Cons:**
- String typos are runtime errors
- Nullable returns (need `.?` everywhere)
- Allocator required
- No compile-time safety

---

## Cost Analysis

### Adding a new spritesheet

| Pattern | Steps | Places to modify |
|---------|-------|------------------|
| Single enum | Add to enum, add init | 2 |
| Categorized enum | Add to category enum, add init | 2 (scoped) |
| HashMap | Call load() | 1 |

### Removing a spritesheet

| Pattern | Compiler helps? | Risk |
|---------|-----------------|------|
| Single enum | Yes - all usages error | Low |
| Categorized enum | Yes - all usages error | Low |
| HashMap | No - runtime error | High |

### Renaming a spritesheet

| Pattern | Compiler helps? |
|---------|-----------------|
| Single enum | Yes |
| Categorized enum | Yes |
| HashMap | No - find/replace needed |

---

## Scaling Strategy

### Small game (< 15 assets)
Use **Single Enum**

### Medium game (15-100 assets)
Use **Categorized Enums**

### Large game (100+ assets)
Use **File-based modules**:

```
src/
  assets/
    mod.zig           // re-exports all
    tiles.zig         // TileSheetId enum + loader
    ui.zig            // UISheetId enum + loader
    characters.zig    // CharSheetId enum + loader
    effects.zig       // EffectSheetId enum + loader
```

Each file owns its enum and loading logic:

```zig
// src/assets/ui.zig
pub const Id = enum {
    button,
    panel,
    icons,
    inventory,
    health_bar,
    mana_bar,
    minimap,
};

pub fn load(sheets: *std.EnumArray(Id, SpriteSheet)) void {
    sheets.set(.button, SpriteSheet.init("ui/button.png", ...));
    sheets.set(.panel, SpriteSheet.init("ui/panel.png", ...));
    // ...
}
```

```zig
// src/assets/mod.zig
pub const tiles = @import("tiles.zig");
pub const ui = @import("ui.zig");
pub const chars = @import("characters.zig");

pub const Assets = struct {
    tiles: std.EnumArray(tiles.Id, SpriteSheet),
    ui: std.EnumArray(ui.Id, SpriteSheet),
    chars: std.EnumArray(chars.Id, SpriteSheet),

    pub fn init() Assets {
        var self: Assets = undefined;
        tiles.load(&self.tiles);
        ui.load(&self.ui);
        chars.load(&self.chars);
        return self;
    }
};
```

**Cost to add new UI asset:**
1. Add to `ui.zig` enum
2. Add load call in `ui.zig`

**Zero changes** to other files.

---

## Decision Matrix

| Question | Answer | Recommendation |
|----------|--------|----------------|
| Total assets < 15? | Yes | Single enum |
| Need runtime loading? | Yes | HashMap |
| Clear categories? | Yes | Categorized enums |
| Assets > 100? | Yes | File-based modules |
| Need hot-reload? | Yes | HashMap + watcher |

---

## Anti-patterns to Avoid

### 1. Global mutable state
```zig
// Bad
var global_assets: Assets = undefined;

pub fn getAssets() *Assets {
    return &global_assets;
}
```

Pass assets explicitly instead.

### 2. String constants for enum-like usage
```zig
// Bad
const TILE_DUNGEON = "tile_dungeon";
const TILE_FOREST = "tile_forest";
assets.get(TILE_DUNGEON);

// Good - use actual enum
assets.tiles.get(.dungeon);
```

### 3. Loading in draw loop
```zig
// Bad - loads every frame!
fn draw() void {
    const sheet = SpriteSheet.init("tiles.png", ...);
    sheet.draw(...);
}

// Good - load once
fn draw(assets: *Assets) void {
    assets.tiles.get(.dungeon).draw(...);
}
```

---

## Summary

1. **Start with categorized enums** - good balance of safety and organization
2. **Split into files** when categories grow large
3. **Use HashMap** only for dynamic/runtime loading needs
4. **Compiler safety > convenience** - enum typos are compile errors, string typos are bugs
