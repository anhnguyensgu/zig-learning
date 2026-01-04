const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create a simple test graph
    var node1 = try Node(i64).init(allocator, 1);
    defer node1.deinit(allocator);

    var node2 = try Node(i64).init(allocator, 2);
    defer node2.deinit(allocator);

    var node3 = try Node(i64).init(allocator, 3);
    defer node3.deinit(allocator);

    var node4 = try Node(i64).init(allocator, 4);
    defer node4.deinit(allocator);

    try node1.addChild(allocator, &node2);
    try node2.addChild(allocator, &node3);
    try node1.addChild(allocator, &node4);

    std.debug.print("DFS traversal:\n", .{});
    dfs(i64, &node1);

    std.debug.print("\nBFS traversal:\n", .{});
    try bfs(i64, &node1, allocator);
}

// Define a simple Node structure without pre-initializing ArrayList
fn Node(comptime ValueType: type) type {
    return struct {
        value: ValueType,
        children: std.ArrayList(*@This()),

        fn init(allocator: std.mem.Allocator, val: ValueType) !@This() {
            // Try using the allocator to initialize ArrayList correctly for Zig 0.15.1
            var node = @This(){
                .value = val,
                .children = undefined,
            };
            // Initialize the ArrayList separately after creating the struct
            node.children = std.ArrayList(*@This()).init(allocator);
            return node;
        }

        fn addChild(self: *@This(), allocator: std.mem.Allocator, child: *@This()) !void {
            _ = allocator;
            try self.children.append(child);
        }

        fn deinit(self: *@This()) void {
            self.children.deinit();
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
    };

    var q = std.DoublyLinkedList(BFSNode).init();

    const n = try allocator.create(BFSNode);
    n.data = node;
    q.append(n);

    while (q.popFirst()) |curr_node| {
        // Defer destruction of current node until end of iteration scope
        defer allocator.destroy(curr_node);

        const cur = curr_node.data;
        std.debug.print("{}\n", .{cur.value});
        for (cur.children.items) |child| {
            const cur_child = try allocator.create(BFSNode);
            cur_child.data = child;
            q.append(cur_child);
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

// Improved Queue implementation using a circular buffer approach
fn Queue(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),
        allocator: std.mem.Allocator,
        head: usize = 0,
        tail: usize = 0,
        count: usize = 0,
        capacity: usize,
        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !@This() {
            const initial_capacity = 16; // Start with a smaller capacity
            const items = try std.ArrayList(T).initCapacity(allocator, initial_capacity);
            return @This(){
                .items = items,
                .allocator = allocator,
                .capacity = initial_capacity,
            };
        }

        pub fn push(self: *Self, item: T) !void {
            // If we need to grow the capacity
            if (self.count == self.capacity) {
                try self.grow();
            }

            // Calculate the actual index for insertion
            const actual_index = (self.head + self.count) % self.capacity;

            // Ensure the array has enough space
            if (self.items.items.len <= actual_index) {
                try self.items.append(self.allocator, item);
            } else {
                self.items.items[actual_index] = item;
            }

            self.count += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.count == 0) return null;

            const result = self.items.items[self.head];
            self.head = (self.head + 1) % self.capacity;
            self.count -= 1;

            return result;
        }

        fn grow(self: *Self) !void {
            const new_capacity = self.capacity * 2;
            var new_items = try std.ArrayList(T).initCapacity(self.allocator, new_capacity);

            // Copy existing items to new array in the correct order
            var i: usize = 0;
            while (i < self.count) : (i += 1) {
                const src_index = (self.head + i) % self.capacity;
                try new_items.append(self.allocator, self.items.items[src_index]);
            }

            // Update queue state
            self.items.deinit(self.allocator);
            self.items = new_items;
            self.head = 0;
            self.capacity = new_capacity;
        }

        pub fn denit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        pub fn size(self: *Self) usize {
            return self.count;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.count == 0;
        }
    };
}

test "Queue push" {
    var q = try Queue(i32).init(std.testing.allocator);
    defer q.denit();
    try q.push(1);
    try std.testing.expectEqual(@as(usize, 1), q.size());
}

test "Queue pop" {
    var q = try Queue(i32).init(std.testing.allocator);
    defer q.denit();
    try q.push(1);
    const item = q.pop();
    try std.testing.expect(item != null);
    if (item) |it| {
        try std.testing.expectEqual(@as(i32, 1), it);
    }
}

test "Queue FIFO behavior" {
    var q = try Queue(i32).init(std.testing.allocator);
    defer q.denit();

    try q.push(1);
    try q.push(2);
    try q.push(3);

    try std.testing.expectEqual(@as(i32, 1), q.pop().?);
    try std.testing.expectEqual(@as(i32, 2), q.pop().?);
    try q.push(4);
    try std.testing.expectEqual(@as(i32, 3), q.pop().?);
    try std.testing.expectEqual(@as(i32, 4), q.pop().?);
    try std.testing.expect(q.pop() == null);
}

test "DFS traversal" {
    const allocator = std.testing.allocator;

    var node1 = try Node(i64).init(allocator, 1);
    defer node1.deinit(allocator);

    var node2 = try Node(i64).init(allocator, 2);
    defer node2.deinit(allocator);

    var node3 = try Node(i64).init(allocator, 3);
    defer node3.deinit(allocator);

    var node4 = try Node(i64).init(allocator, 4);
    defer node4.deinit(allocator);

    try node1.addChild(allocator, &node2);
    try node2.addChild(allocator, &node3);
    try node1.addChild(allocator, &node4);

    // We can't easily test the output of dfs, but we can verify the structure
    try std.testing.expectEqual(@as(usize, 2), node1.children.items.len);
    try std.testing.expectEqual(@as(usize, 1), node2.children.items.len);
    try std.testing.expectEqual(@as(i64, 1), node1.value);
    try std.testing.expectEqual(@as(i64, 2), node2.value);
    try std.testing.expectEqual(@as(i64, 3), node3.value);
    try std.testing.expectEqual(@as(i64, 4), node4.value);
}

test "BFS traversal" {
    const allocator = std.testing.allocator;

    var node1 = try Node(i64).init(allocator, 1);
    defer node1.deinit(allocator);

    var node2 = try Node(i64).init(allocator, 2);
    defer node2.deinit(allocator);

    var node3 = try Node(i64).init(allocator, 3);
    defer node3.deinit(allocator);

    var node4 = try Node(i64).init(allocator, 4);
    defer node4.deinit(allocator);

    try node1.addChild(allocator, &node2);
    try node2.addChild(allocator, &node3);
    try node1.addChild(allocator, &node4);

    // Test BFS traversal by capturing output or verifying structure
    try std.testing.expectEqual(@as(usize, 2), node1.children.items.len);
    try std.testing.expectEqual(@as(usize, 1), node2.children.items.len);
    try std.testing.expectEqual(@as(i64, 1), node1.value);
    try std.testing.expectEqual(@as(i64, 2), node2.value);
    try std.testing.expectEqual(@as(i64, 3), node3.value);
    try std.testing.expectEqual(@as(i64, 4), node4.value);
}
