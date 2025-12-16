const std = @import("std");

pub fn main() !void {
    var stdout_buf: [1 << 16]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    var stdin_buf: [1 << 16]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    var scanner = try Scanner.init(&stdin_reader.interface);
    const N: usize = @intCast(scanner.nextInt());
    try writer.print("{d}\n", .{N});
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
