const std = @import("std");

pub fn main() !void {}

const BTree = struct {
    root: ?*Node,
    allocator: std.mem.Allocator,

    pub fn insert(self: *BTree, key: i64) !void {
        if (self.root) |root| {
            try root.insert(key);
        } else {
            self.root = try Node.new(self.allocator, key);
        }
    }

    pub fn deinit(self: *BTree) void {
        if (self.root) |root| {
            root.deinit();
        }
    }
};

const Node = struct {
    key: i64,
    left: ?*Node = null,
    right: ?*Node = null,
    allocator: std.mem.Allocator,

    fn new(allocator: std.mem.Allocator, key: i64) !*Node {
        const node = try allocator.create(Node);
        node.* = .{
            .allocator = allocator,
            .key = key,
            .left = null,
            .right = null,
        };
        return node;
    }

    fn lowerBound(self: *Node, key: i64) ?*Node {
        if (self.key >= key) {
            if (self.left) |left| {
                return left.lowerBound(key);
            }
            return self;
        }

        if (self.right) |right| {
            return right.lowerBound(key);
        }

        return null;
    }

    fn insert(self: *Node, key: i64) !void {
        if (key <= self.key) {
            if (self.left) |left| {
                try left.insert(key);
            } else {
                self.left = try Node.new(self.allocator, key);
            }
        } else {
            if (self.right) |right| {
                try right.insert(key);
            } else {
                self.right = try Node.new(self.allocator, key);
            }
        }
    }

    fn deinit(self: *Node) void {
        if (self.left) |left| {
            left.deinit();
        }
        if (self.right) |right| {
            right.deinit();
        }
        self.allocator.destroy(self);
    }
};

test "add to empty tree" {
    const allocator = std.testing.allocator;
    var tree = BTree{ .root = null, .allocator = allocator };
    defer tree.deinit();
    try tree.insert(2);
    try std.testing.expectEqual(tree.root.?.key, 2);
}

test "add to left empty, right not empty tree" {
    const allocator = std.testing.allocator;

    const root = try Node.new(allocator, 1);
    var tree = BTree{ .root = root, .allocator = allocator };
    defer tree.deinit();
    try root.insert(2);

    try tree.insert(3);
    try std.testing.expectEqual(tree.root.?.right.?.key, 2);
}

test "add to left not empty, right empty tree" {
    const allocator = std.testing.allocator;

    const root = try Node.new(allocator, 10);
    var tree = BTree{ .root = root, .allocator = allocator };
    defer tree.deinit();
    try root.insert(2);

    try tree.insert(1);
    try std.testing.expectEqual(tree.root.?.left.?.left.?.key, 1);
}

test "add to left not empty, right empty tree, adding larger" {
    const allocator = std.testing.allocator;

    const root = try Node.new(allocator, 10);
    var tree = BTree{ .root = root, .allocator = allocator };
    defer tree.deinit();
    try root.insert(2);

    try tree.insert(3);
    try std.testing.expectEqual(tree.root.?.left.?.right.?.key, 3);
}

test "lower bound" {
    const allocator = std.testing.allocator;
    var tree = BTree{ .root = null, .allocator = allocator };
    defer tree.deinit();
    try tree.insert(2);
    try tree.insert(3);
    try tree.insert(4);
    try std.testing.expectEqual(tree.root.?.lowerBound(2).?.key, 2);
}
