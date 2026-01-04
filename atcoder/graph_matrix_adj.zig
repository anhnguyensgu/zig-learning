const std = @import("std");

const MAX_ROW = 1000;
pub fn main() !void {
    var stdout_buf: [1 << 16]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    var stdin_buf: [1 << 16]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    var scanner = try Scanner.init(&stdin_reader.interface);
    const n: usize = @intCast(scanner.nextInt());
    const m: usize = @intCast(scanner.nextInt());

    var matrix: [MAX_ROW][MAX_ROW]i32 = .{.{0} ** MAX_ROW} ** MAX_ROW;
    for (0..m) |_| {
        const a: usize = @intCast(scanner.nextInt());
        const b: usize = @intCast(scanner.nextInt());
        matrix[a][b] = 1;
    }
    const start: usize = @intCast(scanner.nextInt());
    const k: usize = @intCast(scanner.nextInt());
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var current_set = try allocator.alloc(bool, n);
    @memset(current_set, false);
    current_set[start] = true;
    for (1..k + 1) |_| {
        var new_set = try allocator.alloc(bool, n);
        @memset(new_set, false);
        for (0..n) |i| {
            if (current_set[i]) {
                for (0..n) |j| {
                    if (matrix[i][j] == 1) {
                        new_set[j] = true;
                    }
                }
            }
        }
        current_set = new_set;
    }
    try writer.print("Cities reachable in exactly {} steps:", .{k});
    for (0..n) |i| {
        if (!current_set[i]) continue;
        try writer.print(" {}", .{i});
    }
    try writer.print("\n", .{});
    try writer.flush();
}

const Scanner = struct {
    buf: [1 << 16]u8 = undefined,
    r: *std.io.Reader,

    fn init(r: *std.io.Reader) !Scanner {
        return .{ .r = r };
    }

    fn nextToken(self: *Scanner) []const u8 {
        var l: usize = 0;
        while (true) {
            const c = self.r.takeByte() catch |err| switch (err) {
                error.EndOfStream => break,
                else => @panic("Unexpected error"),
            };
            if (std.ascii.isWhitespace(c)) break;
            self.buf[l] = c;
            l += 1;
        }
        return self.buf[0..l];
    }

    fn nextInt(self: *Scanner) i64 {
        const tok = self.nextToken();
        return std.fmt.parseInt(i64, tok, 10) catch {
            @panic("parseInt failed");
        };
    }
};


// Problem: Reachable in K Steps
//
// Given a directed graph, determine which cities you can reach from a starting city in exactly K steps.
//
// Task:
// 1. Build an adjacency matrix for a directed graph
// 2. Starting from city S, find all cities reachable in exactly K steps
// 3. A step means following one edge
//
// Input Format:
// First line: n (number of cities, labeled 0 to n-1)
// Second line: m (number of roads - directed)
// Next m lines: two integers a b (road from city a to city b)
// Last line: S K (starting city and number of steps)
//
// Output Format:
// Cities reachable in exactly K steps: [list of cities in ascending order]
// (or "None" if no cities reachable)
//
// ---
// Sample Input
//
// 4
// 5
// 0 1
// 0 2
// 1 2
// 1 3
// 2 3
// 0 2
//
// Sample Output
//
// Cities reachable in exactly 2 steps: 2 3
//
// Explanation: Starting from city 0, in exactly 2 steps:
// - 0 → 1 → 2 ✓
// - 0 → 1 → 3 ✓
// - 0 → 2 → 3 ✓
//
// So cities {2, 3} are reachable.

// =============== Optimization ===============
// Time Complexity Comparison
//
// Bool Array (your current code):
//
// Time: O(K × n × n)
// Space: O(n)
//
// Always check all n cities, all n neighbors
//
// HashSet:
//
// Time: O(K × r × n)
// Space: O(r)
//
// r = reachable cities (only iterate these)
// No conversion overhead
//
// Hybrid (Bool + ArrayList):
//
// Time: O(K × (r × n + n))
// Space: O(n + r)
//
// r × n: iterate reachable cities
// + n: convert bool → list (overhead!)
//
// ---
// Head-to-head: HashSet vs Hybrid
//
// Scenario: n=1000, r=10, K=5
//
// HashSet:     5 × (10 × 1000) = 50,000 iterations
// Hybrid:      5 × (10 × 1000 + 1000) = 55,000 iterations
//                                 ^^^^
//                           conversion overhead!
//
// HashSet is ~10% faster due to no conversion
//
// ---
// Code Complexity
//
// Bool Array (simplest):
//
// var current = alloc(bool, n);
// @memset(current, false);
// current[start] = true;
//
// for (0..k) |_| {
//     var next = alloc(bool, n);
//     @memset(next, false);
//
//     for (0..n) |i| {
//         if (current[i]) {
//             for (0..n) |j| {
//                 if (matrix[i][j] == 1) {
//                     next[j] = true;
//                 }
//             }
//         }
//     }
//     current = next;
// }
// Lines of code: ~10
// Concepts: Arrays, loops
// Easy to understand: ✅✅✅
//
// ---
// HashSet (cleanest for optimization):
//
// var current = std.AutoHashMap(usize, void).init(allocator);
// try current.put(start, {});
//
// for (0..k) |_| {
//     var next = std.AutoHashMap(usize, void).init(allocator);
//
//     var iter = current.keyIterator();
//     while (iter.next()) |city| {
//         for (0..n) |neighbor| {
//             if (matrix[city.*][neighbor] == 1) {
//                 try next.put(neighbor, {});
//             }
//         }
//     }
//     current = next;
// }
//
// // Convert to array for output
// var result = ArrayList(usize).init(allocator);
// var iter = current.keyIterator();
// while (iter.next()) |city| {
//     try result.append(city.*);
// }
// Lines of code: ~15
// Concepts: HashMap, iterators
// Easy to understand: ✅✅
//
// ---
// Hybrid (most complex):
//
// var current_list = ArrayList(usize).init(allocator);
// try current_list.append(start);
//
// for (0..k) |_| {
//     // Phase 1: Build with bool
//     var next_bool = alloc(bool, n);
//     @memset(next_bool, false);
//
//     for (current_list.items) |city| {
//         for (0..n) |neighbor| {
//             if (matrix[city][neighbor] == 1) {
//                 next_bool[neighbor] = true;
//             }
//         }
//     }
//
//     // Phase 2: Convert to list
//     var next_list = ArrayList(usize).init(allocator);
//     for (0..n) |i| {
//         if (next_bool[i]) {
//             try next_list.append(i);
//         }
//     }
//
//     current_list = next_list;
// }
// Lines of code: ~20
// Concepts: ArrayList, bool array, conversion
// Easy to understand: ✅ (more mental overhead)
//
// ---
// Performance Comparison Table
//
// | Metric               | Bool Array | HashSet  | Hybrid       |
// |----------------------|------------|----------|--------------|
// | Time (sparse)        | O(K×n²)    | O(K×r×n) | O(K×(r×n+n)) |
// | Time (dense)         | O(K×n²)    | O(K×n²)  | O(K×n²)      |
// | Space                | O(n)       | O(r)     | O(n+r)       |
// | Code lines           | ~10        | ~15      | ~20          |
// | Simplicity           | ⭐⭐⭐     | ⭐⭐     | ⭐           |
// | Performance (sparse) | ⭐         | ⭐⭐⭐   | ⭐⭐         |
// | Performance (dense)  | ⭐⭐⭐     | ⭐⭐⭐   | ⭐⭐         |
//
// ---
// Verdict:
//
// ✅ Use Bool Array when:
//
// - Learning/educational purposes
// - Small graphs (n < 100)
// - Simplicity matters
// - This is what you have now - it's perfect for learning!
//
// ✅ Use HashSet when:
//
// - Large sparse graphs (n > 1000, r << n)
// - Competitive programming
// - Best balance of performance + clean code
// - If you optimize, choose this one!
//
// ❌ Avoid Hybrid because:
//
// - More complex than HashSet
// - Slower than HashSet (conversion overhead)
// - Only slightly better space usage
// - No real advantage over HashSet
//
// ---
// My recommendation:
//
// Ranking for optimization:
// 1. HashSet - best performance + cleaner code
// 2. Bool Array - simplest, good enough for most cases
// 3. Hybrid - worst of both worlds (complexity + overhead)
//
// For your learning:
// Keep the bool array! It's clear, correct, and teaches the core concept.
//
// If you want to try optimization:
// Jump straight to HashSet, skip the hybrid approach.
//
// Want to see the HashSet implementation for comparison?
