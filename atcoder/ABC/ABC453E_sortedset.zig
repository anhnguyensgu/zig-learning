const std = @import("std");

const Node = struct {
    l: i64,          // half-open [l, r)
    r: i64,
    prio: u32,
    left: u32 = 0,   // 0 = null
    right: u32 = 0,
};

const Scanner = struct {
    buf: [1 << 20]u8 = undefined, // 1 MiB
    pos: usize = 0,
    len: usize = 0,

    fn refill(self: *Scanner) void {
        self.len = std.posix.read(std.posix.STDIN_FILENO, self.buf[0..]) catch 0;
        self.pos = 0;
    }

    fn peekByte(self: *Scanner) u8 {
        if (self.pos >= self.len) {
            self.refill();
            if (self.len == 0) @panic("Unexpected EOF");
        }
        return self.buf[self.pos];
    }

    fn takeByte(self: *Scanner) u8 {
        const c = self.peekByte();
        self.pos += 1;
        return c;
    }

    fn skipSpaces(self: *Scanner) void {
        while (true) {
            const c = self.peekByte();
            if (!std.ascii.isWhitespace(c)) return;
            _ = self.takeByte();
        }
    }

    fn nextI64(self: *Scanner) i64 {
        self.skipSpaces();
        var c = self.takeByte();

        var sign: i64 = 1;
        if (c == '-') {
            sign = -1;
            c = self.takeByte();
        }

        var x: i64 = 0;
        while (c >= '0' and c <= '9') {
            x = x * 10 + @as(i64, c - '0');
            if (self.pos >= self.len) {
                self.refill();
                if (self.len == 0) break;
            }
            c = self.takeByte();
        }

        // If we stopped on a non-space, unread one byte (safe: within buffer)
        if (!std.ascii.isWhitespace(c)) self.pos -= 1;

        return x * sign;
    }
};

const Treap = struct {
    nodes: []Node,
    next: u32 = 0, // next index to allocate (1-based)
    root: u32 = 0,
    rng: u64 = 88172645463393265,

    fn randU32(self: *Treap) u32 {
        // xorshift64*
        var x = self.rng;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.rng = x;
        return @intCast((x *% 2685821657736338717) >> 32);
    }

    fn newNode(self: *Treap, l: i64, r: i64) u32 {
        self.next += 1;
        const idx = self.next;
        self.nodes[idx] = .{ .l = l, .r = r, .prio = self.randU32(), .left = 0, .right = 0 };
        return idx;
    }

    fn merge(self: *Treap, a: u32, b: u32) u32 {
        if (a == 0) return b;
        if (b == 0) return a;

        if (self.nodes[a].prio > self.nodes[b].prio) {
            self.nodes[a].right = self.merge(self.nodes[a].right, b);
            return a;
        } else {
            self.nodes[b].left = self.merge(a, self.nodes[b].left);
            return b;
        }
    }

    // Split by key on l:
    // left: l < key, right: l >= key
    fn split(self: *Treap, t: u32, key: i64, left_out: *u32, right_out: *u32) void {
        if (t == 0) {
            left_out.* = 0;
            right_out.* = 0;
            return;
        }
        if (self.nodes[t].l < key) {
            var a: u32 = 0;
            var b: u32 = 0;
            self.split(self.nodes[t].right, key, &a, &b);
            self.nodes[t].right = a;
            left_out.* = t;
            right_out.* = b;
        } else {
            var a: u32 = 0;
            var b: u32 = 0;
            self.split(self.nodes[t].left, key, &a, &b);
            self.nodes[t].left = b;
            left_out.* = a;
            right_out.* = t;
        }
    }

    fn popMax(self: *Treap, t: u32, new_root: *u32) u32 {
        // returns max node index by l, and writes remaining root
        if (self.nodes[t].right == 0) {
            new_root.* = self.nodes[t].left;
            self.nodes[t].left = 0;
            return t;
        }
        const mx = self.popMax(self.nodes[t].right, &self.nodes[t].right);
        new_root.* = t;
        return mx;
    }

    fn popMin(self: *Treap, t: u32, new_root: *u32) u32 {
        // returns min node index by l, and writes remaining root
        if (self.nodes[t].left == 0) {
            new_root.* = self.nodes[t].right;
            self.nodes[t].right = 0;
            return t;
        }
        const mn = self.popMin(self.nodes[t].left, &self.nodes[t].left);
        new_root.* = t;
        return mn;
    }

    fn insertNode(self: *Treap, root: u32, idx: u32) u32 {
        var a: u32 = 0;
        var b: u32 = 0;
        self.split(root, self.nodes[idx].l, &a, &b);
        return self.merge(self.merge(a, idx), b);
    }
};

pub fn main() !void {
    var sc: Scanner = .{};

    const N: i64 = sc.nextI64();
    const Q: usize = @intCast(sc.nextI64());

    const alloc = std.heap.page_allocator;
    // Node upper bound: start with 1 interval; each query can create at most 1 extra (split left piece).
    // Allocate ~ (Q + 5) safely; (2Q+5) is also fine.
    const nodes = try alloc.alloc(Node, Q + 10);
    defer alloc.free(nodes);

    var treap = Treap{ .nodes = nodes };
    // allocate node index 1..next, keep 0 as null sentinel
    _ = treap.newNode(1, N + 1);
    treap.root = 1;

    var white: i64 = N;

    // buffered output
    var out = std.ArrayList(u8){};
    defer out.deinit(alloc);
    try out.ensureTotalCapacity(alloc, Q * 12);

    var qi: usize = 0;
    while (qi < Q) : (qi += 1) {
        const L: i64 = sc.nextI64();
        const R_in: i64 = sc.nextI64();
        const R1: i64 = R_in + 1; // half-open [L, R1)

        // Split by L: A has l < L, B has l >= L
        var A: u32 = 0;
        var B: u32 = 0;
        treap.split(treap.root, L, &A, &B);

        // Check the rightmost interval in A; it might overlap [L, R1)
        if (A != 0) {
            var A2: u32 = 0;
            const idx = treap.popMax(A, &A2); // idx has max l in old A
            const il = treap.nodes[idx].l;
            const ir = treap.nodes[idx].r;

            if (ir <= L) {
                // no overlap, put it back
                A = treap.merge(A2, idx);
            } else {
                // overlap: split this interval into [il, L) and [L, ir)
                if (il < L) {
                    const left_idx = treap.newNode(il, L);
                    A = treap.merge(A2, left_idx);
                } else {
                    A = A2;
                }
                // reuse idx as the right piece starting at L
                treap.nodes[idx].l = L;
                treap.nodes[idx].r = ir;
                treap.nodes[idx].left = 0;
                treap.nodes[idx].right = 0;
                B = treap.insertNode(B, idx);
            }
        }

        // Now split B by R1: Mid has l < R1, C has l >= R1
        var Mid: u32 = 0;
        var C: u32 = 0;
        treap.split(B, R1, &Mid, &C);

        // Remove [L, R1) from all intervals in Mid (they all start in [L, R1))
        // For each interval [l,r):
        // covered_len = min(r, R1) - l  (since l < R1 always)
        // leftover tail exists only if r > R1, becomes [R1, r) (and goes to C).
        while (Mid != 0) {
            var Mid2: u32 = 0;
            const idx = treap.popMin(Mid, &Mid2);
            Mid = Mid2;

            const il = treap.nodes[idx].l;
            const ir = treap.nodes[idx].r;
            const cut_end = if (ir < R1) ir else R1;
            white -= (cut_end - il);

            if (ir > R1) {
                // reuse idx as tail [R1, ir) and insert into C
                treap.nodes[idx].l = R1;
                treap.nodes[idx].r = ir;
                treap.nodes[idx].left = 0;
                treap.nodes[idx].right = 0;
                C = treap.insertNode(C, idx);
                // After this, no other interval can be in Mid (disjoint + tail extends past R1),
                // but Mid should already be 0. Even if not, continuing is safe.
            }
            // else: fully covered; discard idx
        }

        treap.root = treap.merge(A, C);

        // output white
        try out.writer(alloc).print("{d}\n", .{white});
    }

    _ = try std.posix.write(std.posix.STDOUT_FILENO, out.items);
}
