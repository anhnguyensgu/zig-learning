const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const writer = stdout.deprecatedWriter();

    var stdin_buf: [1 << 16]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    var scanner = try Scanner.init(&stdin_reader.interface);
    const N: usize = @intCast(scanner.nextInt());
    if (N == 0) {
        try writer.print("{d}\n", .{0});
        return;
    }

    var i: usize = 0;
    var nums: [51]i64 = undefined;
    while (i < N) : (i += 1) {
        const x = scanner.nextInt();
        nums[i] = x;
    }
    i = 0;
    var ans: i64 = 0;
    while (i < N - 1) : (i += 1) {
        var j = i + 1;
        while (j < N) : (j += 1) {
            var k = i;
            var sum: i64 = 0;
            while (k <= j) : (k += 1) {
                sum += nums[k];
            }
            k = i;
            var ok = true;
            while (k <= j) : (k += 1) {
                if (@mod(sum, nums[k]) == 0) {
                    ok = false;
                    break;
                }
            }
            if (ok) {
                ans += 1;
            }
        }
    }

    try writer.print("{d}\n", .{ans});
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
