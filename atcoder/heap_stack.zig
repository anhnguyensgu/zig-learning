const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== 1. BAD ARRAY (Stack Bug) ===\n", .{});
    // This looks fine, but it crashes or corrupts memory!
    const bad = BadArray.init(allocator);

    // Write to the dangling pointer
    bad.items[0] = 99;
    std.debug.print("Set Bad Value: {d}\n", .{bad.items[0]});

    // Clobber the stack to prove it's broken
    clobberStack();
    std.debug.print("Bad Value after interference: {d} (CORRUPTED!)\n\n", .{bad.items[0]});

    std.debug.print("=== 2. GOOD ARRAY (Heap Correct) ===\n", .{});
    // This allocates properly on the heap
    var good = GoodArray.init(allocator, 100) catch unreachable;
    defer good.deinit();

    good.items[0] = 99;
    std.debug.print("Set Good Value: {d}\n", .{good.items[0]});

    // Clobber the stack again to prove we are safe
    clobberStack();
    std.debug.print("Good Value after interference: {d} (SAFE!)\n", .{good.items[0]});
}

fn clobberStack() void {
    var garbage: [100]i64 = undefined;
    @memset(&garbage, -1);
}

// ---------------------------------------------------------
// ❌ WRONG VERSION: Uses stack memory that dies after init()
// ---------------------------------------------------------
const BadArray = struct {
    items: []i64,
    size: usize,

    fn init(allocator: std.mem.Allocator) BadArray {
        _ = allocator; // Unused here
        // ERROR: This array lives on the STACK of this function.
        var stack_memory: [100]i64 = undefined;

        return BadArray{
            // ERROR: Returning a pointer to local stack memory!
            // When this function returns, 'stack_memory' is considered "free"
            // and will be overwritten by other functions (like clobberStack).
            .items = stack_memory[0..],
            .size = 0,
        };
    }
};

// ---------------------------------------------------------
// ✅ CORRECT VERSION: Uses Allocator to get Heap memory
// ---------------------------------------------------------
const GoodArray = struct {
    allocator: std.mem.Allocator,
    items: []i64,
    size: usize,

    fn init(allocator: std.mem.Allocator, capacity: usize) !GoodArray {
        // CORRECT: Ask allocator for memory. This lives until we free it.
        const heap_memory = try allocator.alloc(i64, capacity);

        return GoodArray{
            .allocator = allocator,
            .items = heap_memory,
            .size = 0,
        };
    }

    fn deinit(self: GoodArray) void {
        // CLEANUP: We must free what we allocated
        self.allocator.free(self.items);
    }
};
