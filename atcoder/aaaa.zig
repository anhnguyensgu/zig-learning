const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const writer = stdout.deprecatedWriter();

    // Read input using direct posix read
    var buf: [4096]u8 = undefined;
    const n = std.posix.read(std.posix.STDIN_FILENO, &buf) catch 0;
    const input = std.mem.trim(u8, buf[0..n], &std.ascii.whitespace);

    // Parse integers from the line
    var it = std.mem.splitScalar(u8, input, ' ');

    // Example: read two integers
    const a = std.fmt.parseInt(i64, it.next().?, 10) catch 0;

    // Calculate result (example: sum)
    const result = @divExact(a * (a + 1), 2);

    // Print output
    try writer.print("{d}\n", .{result});
}

// Helper function to parse a single integer from a string
fn parseInt(s: []const u8) i64 {
    const trimmed = std.mem.trim(u8, s, &std.ascii.whitespace);
    return std.fmt.parseInt(i64, trimmed, 10) catch 0;
}

// Helper function to parse multiple integers from a line
fn parseInts(comptime T: type, input: []const u8, out_buf: []T) []T {
    var it = std.mem.splitScalar(u8, input, ' ');
    var i: usize = 0;
    while (it.next()) |token| {
        if (i >= out_buf.len) break;
        const trimmed = std.mem.trim(u8, token, &std.ascii.whitespace);
        if (trimmed.len == 0) continue;
        out_buf[i] = std.fmt.parseInt(T, trimmed, 10) catch 0;
        i += 1;
    }
    return out_buf[0..i];
}

// Helper function to read all input
fn readAll(buf: []u8) []const u8 {
    const n = std.posix.read(std.posix.STDIN_FILENO, buf) catch 0;
    return std.mem.trim(u8, buf[0..n], &std.ascii.whitespace);
}
