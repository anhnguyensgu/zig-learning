const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello, world!\n", .{});
}

fn Node(comptime ValueType: type) type {
    return struct {
        value: ValueType,
        children: std.ArrayList(*@This()) = .{},

        fn addChild(self: *@This(), allocator: std.mem.Allocator, child: *@This()) !void {
            try self.children.append(allocator, child);
        }
    };
}

fn dfs(comptime Type: type, node: *Node(Type)) void {
    std.debug.print("{}\n", .{node.value});
    for (node.children.items) |child| {
        dfs(Type, child);
    }
}

fn bfsWithLinkedList(comptime Type: type, node: *Node(Type), allocator: std.mem.Allocator) !void {
    const BFSNode = struct {
        data: *Node(Type),
        link: std.DoublyLinkedList.Node = .{},
    };
    var q = std.DoublyLinkedList{};

    const n = try allocator.create(BFSNode);
    n.data = node;
    q.append(&n.link);

    while (q.popFirst()) |link| {
        const curr_node: *BFSNode = @fieldParentPtr("link", link);
        // Defer destruction of current node until end of iteration scope
        defer allocator.destroy(curr_node);

        const cur = curr_node.data;
        std.debug.print("{}\n", .{cur.value});
        for (cur.children.items) |child| {
            const cur_child = try allocator.create(BFSNode);
            cur_child.data = child;
            q.append(&cur_child.link);
        }
    }
}

fn bfs(comptime Type: type, node: *Node(Type), allocator: std.mem.Allocator) !void {
    var q = try Queue(*Node(Type)).init(allocator);
    defer q.denit();
    try q.push(node);

    while (q.pop()) |cur_node| {
        std.debug.print("{}\n", .{cur_node.value});
        for (cur_node.children.items) |child| {
            try q.push(child);
        }
    }
}

fn Queue(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),
        allocator: std.mem.Allocator,
        head: usize = 0,
        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !@This() {
            const items = try std.ArrayList(T).initCapacity(allocator, 1000);
            return @This(){
                .items = items,
                .allocator = allocator,
            };
        }

        pub fn push(self: *Self, item: T) !void {
            try self.items.append(self.allocator, item);
        }

        pub fn pop(self: *Self) ?T {
            if (self.head >= self.items.items.len) return null;
            const result = self.items.items[self.head];
            self.head += 1;
            return result;
        }

        pub fn denit(self: *Self) void {
            self.items.deinit(self.allocator);
        }
    };
}

test "Queue push" {
    var q = try Queue(i32).init(std.testing.allocator);
    defer q.denit();
    try q.push(1);
    try std.testing.expectEqual(1, q.items.items.len);
}

test "Queue pop" {
    var q = try Queue(i32).init(std.testing.allocator);
    defer q.denit();
    try q.push(1);
    const item = q.pop();
    if (item) |it| {
        try std.testing.expectEqual(1, it);
    } else {
        try std.testing.expect(false);
    }
}

test "dfs" {
    const allocator = std.testing.allocator;
    var node1 = Node(i64){ .value = 1 };
    defer node1.children.deinit(allocator);
    var node2 = Node(i64){ .value = 2 };
    var node4 = Node(i64){ .value = 4 };
    defer node2.children.deinit(allocator);
    var node3 = Node(i64){ .value = 3 };
    try node1.addChild(allocator, &node2);
    try node2.addChild(allocator, &node3);
    try node1.addChild(allocator, &node4);
    try bfs(i64, &node1, allocator);
}
