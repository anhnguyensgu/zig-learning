const std = @import("std");
pub fn foo() void {
    std.debug.print("hello world", .{});
}

pub const Signer = struct {
    const Self = @This();
};

const Keypair = struct {
    const Self = @This();
};

pub const Node = struct {
    const Self = @This();
    singer: *Signer,

    pub fn load_from() Self {
        std.debug.print("load from path\n", .{});
        return Self{ .singer = undefined };
    }
};

pub fn CreateNode(comptime S: type) type {
    return struct {
        const Self = @This();
        singer: *S,

        pub fn load_from() Self {
            std.debug.print("load from path\n", .{});
            return Self{ .singer = undefined };
        }

        pub fn run(self: *const Self) void {
            _ = self;
            std.debug.print("Node is running\n", .{});
        }
    };
}
