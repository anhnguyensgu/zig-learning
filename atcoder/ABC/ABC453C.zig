const std = @import("std");

var nums: [10E6]i64 = undefined;
pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const writer = stdout.deprecatedWriter();

    var stdin_buf: [1 << 16]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    var scanner = try Scanner.init(&stdin_reader.interface);

    const N: usize = @intCast(scanner.nextInt());
    for (0..N) |i| {
        nums[i] = scanner.nextInt();
    }
    var max_reach: usize = 0;
    for (0..N) |i| {
        if (max_reach < i) {
            break;
        }
        const next_reach = i + @as(usize, @intCast(nums[i] - 1));
        max_reach = @max(next_reach, max_reach);
    }

    try writer.print("{}\n", .{@min(max_reach + 1, N)});
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
