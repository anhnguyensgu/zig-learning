const std = @import("std");

const Scanner = struct {
    buf: [1 << 20]u8 = undefined, // 1 MiB
    pos: usize = 0,
    len: usize = 0,

    fn refill(self: *Scanner) void {
        self.len = std.posix.read(std.posix.STDIN_FILENO, self.buf[0..]) catch 0;
        self.pos = 0;
    }

    fn readByte(self: *Scanner) u8 {
        if (self.pos >= self.len) {
            self.refill();
            if (self.len == 0) @panic("Unexpected EOF");
        }
        const c = self.buf[self.pos];
        self.pos += 1;
        return c;
    }

    fn skipSpaces(self: *Scanner) void {
        while (true) {
            const c = self.readByte();
            if (!std.ascii.isWhitespace(c)) {
                self.pos -= 1; // unread 1 byte
                return;
            }
        }
    }

    fn nextI64(self: *Scanner) i64 {
        self.skipSpaces();
        var c = self.readByte();

        var sign: i64 = 1;
        if (c == '-') {
            sign = -1;
            c = self.readByte();
        }

        var x: i64 = 0;
        while (c >= '0' and c <= '9') {
            x = x * 10 + @as(i64, c - '0');
            // safe peek by reading; if whitespace, stop (we can't unread easily except 1 byte)
            if (self.pos >= self.len) {
                self.refill();
                if (self.len == 0) break;
            }
            c = self.readByte();
        }

        // if we stopped on a non-space that isn't EOF, step back 1
        if (!std.ascii.isWhitespace(c)) self.pos -= 1;

        return x * sign;
    }
};

fn lowerBound(a: []const i64, x: i64) usize {
    var lo: usize = 0;
    var hi: usize = a.len;
    while (lo < hi) {
        const mid = (lo + hi) >> 1;
        if (a[mid] < x) lo = mid + 1 else hi = mid;
    }
    return lo;
}

fn find(parent: []usize, x: usize) usize {
    var v = x;
    while (parent[v] != v) v = parent[v];

    // path compression
    var u = x;
    while (parent[u] != u) {
        const p = parent[u];
        parent[u] = v;
        u = p;
    }
    return v;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    var sc: Scanner = .{};
    // Read N, Q
    const N: i64 = sc.nextI64();
    const Q: usize = @intCast(sc.nextI64());

    var Ls = try alloc.alloc(i64, Q);
    var Rs1 = try alloc.alloc(i64, Q); // store R+1 (half-open)
    defer alloc.free(Ls);
    defer alloc.free(Rs1);

    var coords = try alloc.alloc(i64, 2 * Q + 2);
    defer alloc.free(coords);

    var m: usize = 0;
    coords[m] = 1; m += 1;
    coords[m] = N + 1; m += 1;

    for (0..Q) |i| {
        const L = sc.nextI64();
        const R = sc.nextI64();
        Ls[i] = L;
        Rs1[i] = R + 1;

        coords[m] = L; m += 1;
        coords[m] = R + 1; m += 1;
    }

    // sort + unique coords[0..m)
    std.sort.pdq(i64, coords[0..m], {}, comptime std.sort.asc(i64));

    var uniq: usize = 0;
    for (0..m) |i| {
        if (i == 0 or coords[i] != coords[i - 1]) {
            coords[uniq] = coords[i];
            uniq += 1;
        }
    }
    const xs = coords[0..uniq];
    const segCount: usize = uniq - 1; // segments [xs[i], xs[i+1])

    // DSU parent: next unpainted segment index
    var parent = try alloc.alloc(usize, segCount + 1);
    defer alloc.free(parent);
    for (0..segCount + 1) |i| parent[i] = i;

    var black_len: i64 = 0;

    var out_buf: [1 << 16]u8 = undefined;
    var out_writer = std.fs.File.stdout().writer(&out_buf);
    const out = &out_writer.interface;
    defer out.flush() catch {};

    for (0..Q) |qi| {
        const L = Ls[qi];
        const R1 = Rs1[qi];

        const il = lowerBound(xs, L);
        const ir = lowerBound(xs, R1); // paint segments [il .. ir-1]

        var cur = find(parent, il);
        while (cur < ir) {
            black_len += xs[cur + 1] - xs[cur];
            parent[cur] = find(parent, cur + 1);
            cur = parent[cur];
        }

        try out.print("{d}\n", .{N - black_len});
    }
}
