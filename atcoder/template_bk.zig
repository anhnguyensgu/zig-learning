const std = @import("std");

pub fn main() !void {
    const stdout = std.fs.File.stdout();
    const writer = stdout.deprecatedWriter();

    var stdin_buf: [1 << 16]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    var scanner = try Scanner.init(&stdin_reader.interface);

    const n = scanner.nextInt();
    if (n <= 0) {
        try writer.print("0\n", .{});
        return;
    }

    // N is at most 50 per problem statement
    if (n > 50) {
        @panic("N > 50, invalid input for this problem");
    }
    const n_usize: usize = @intCast(n);

    var nums: [50]i64 = undefined;

    var i: usize = 0;
    while (i < n_usize) : (i += 1) {
        const v = scanner.nextInt();
        if (v <= 0) {
            @panic("Ai must be positive");
        }
        nums[i] = v;
    }

    var ans: i64 = 0;

    // Enumerate all subarrays [l, r]
    var l: usize = 0;
    while (l < n_usize) : (l += 1) {
        var sum: i64 = 0;
        var r: usize = l;
        while (r < n_usize) : (r += 1) {
            sum += nums[r];

            var ok = true;
            var k: usize = l;
            while (k <= r) : (k += 1) {
                const a = nums[k]; // > 0 by construction
                // no risk of division by zero
                if (@mod(sum, a) == 0) {
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

        // Skip leading whitespace
        while (true) {
            const c = self.r.takeByte() catch |err| switch (err) {
                error.EndOfStream => return self.buf[0..0],
                else => @panic("Unexpected error"),
            };
            if (!std.ascii.isWhitespace(c)) {
                self.buf[l] = c;
                l += 1;
                break;
            }
        }

        // Read token bytes
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
        if (tok.len == 0) @panic("Unexpected EOF while reading int");
        return std.fmt.parseInt(i64, tok, 10) catch {
            @panic("parseInt failed");
        };
    }
};
