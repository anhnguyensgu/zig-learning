const std = @import("std");

fn makeCubes(comptime n: usize) [n]usize {
    var out: [n]usize = undefined;
    inline for (0..n) |i| {
        out[i] = i * i * i;
    }
    return out;
}

fn isSignedInt(comptime T: type) u16 {
    const info = @typeInfo(T);
    comptime if (info != .int) @compileError("int only");
    return info.int.bits;
}

fn requireSized(comptime T: type, comptime size: u16) void {
    const current_size = @sizeOf(T);

    if (current_size != size) {
        @compileError("wrong size");
    }
}

const User = struct {
    id: u32,
    active: bool,
};

fn countFields(comptime T: type) usize {
    const info = @typeInfo(T);
    comptime if (info != .@"struct") @compileError("only struct");
    const ans = comptime blk: {
        var c: usize = 0;
        for (info.@"struct".fields) |_| {
            c += 1;
        }
        break :blk c;
    };
    return ans;
}
test "countFields" {
    const count = countFields(User);
    std.debug.print("countFields(User) = {}\n", .{count});
}
fn Vec2(comptime T: type) type {
    return struct { x: T,
        y: T,

        pub fn add(self: @This(), other: @This()) @This() {
            return .{ .x = self.x + other.x, .y = self.y + other.y };
        }
        pub fn scale(self: @This(), k: i32) @This() {
            return .{ .x = self.x * k, .y = self.y * k };
        }
    };
}

fn repeat(comptime n: usize, x: anytype) [n]@TypeOf(x) {
    var out: [n]@TypeOf(x) = undefined;
    inline for (0..n) |i| {
        out[i] = x;
    }
    return out;
}

fn makeFilled(comptime n: usize, value: u8) [n]u8 {
    var out: [n]u8 = undefined;
    inline for (0..out.len) |i| {
        out[i] = value;
    }
    return out;
}

test "repeat types" {
    const arr = repeat(3, @as(u8, 7));
    inline for (arr) |i| {
        std.debug.print("v = {}\n", .{i});
    }
    std.debug.print("arr = {}\n", .{arr.len});
}

test "makeFilled" {
    const arr = makeFilled(3, @as(u8, 7));
    inline for (arr) |i| {
        std.debug.print("v = {}\n", .{i});
    }
    std.debug.print("arr = {}\n", .{arr.len});
}

test "sum up" {
    const a = sum(5, i64);
    std.debug.print("sum: {}", .{a});
}

fn sum(comptime n: usize, comptime T: type) T {
    var result: T = 0;
    inline for (1..n + 1) |i| {
        result += i;
    }

    return result;
}

fn enumFromString(comptime E: type, s: []const u8) ?E {
    const info = @typeInfo(E);
    comptime if (info != .@"enum") @compileError("enum only");

    inline for (info.@"enum".fields) |f| {
        if (std.mem.eql(u8, s, f.name)) {
            return @enumFromInt(f.value);
        }
    }
    return null;
}

test "enumFromstring" {
    const Color = enum { red, green, blue };

    const c1 = enumFromString(Color, "green"); // should be .green
    const c2 = enumFromString(Color, "yellow"); // should be null
    try std.testing.expectEqual(Color.green, c1);
    try std.testing.expectEqual(null, c2);
}
