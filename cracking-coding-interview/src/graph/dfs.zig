const Node = @import("node.zig").Node;
const std = @import("std");

fn dfs(node: *Node, visited: *std.AutoHashMap(*Node, void)) !void {
    if (visited.contains(node)) {
        std.debug.print("Already visited node with value: {}\n", .{node.value});
        return;
    }

    try visited.put(node, {});
    std.debug.print("Visiting node with value: {}\n", .{node.value});
    for (node.nodes) |*child| {
        try dfs(child.*, visited);
    }
}

fn HashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}

test "dfs simple linear path" {
    const allocator = std.testing.allocator;
    var visited = HashSet(*Node).init(allocator);
    defer visited.deinit();

    // Create a linear path A -> B -> C
    var A = Node{ .nodes = &.{}, .value = 1 };
    var B = Node{ .nodes = &.{}, .value = 2 };
    var C = Node{ .nodes = &.{}, .value = 3 };
    // Set up connections
    var B_nodes = [_]*Node{&C};
    var A_nodes = [_]*Node{&B};
    B.nodes = B_nodes[0..];
    A.nodes = A_nodes[0..];

    try dfs(&A, &visited);

    try std.testing.expect(visited.contains(&A));
    try std.testing.expect(visited.contains(&B));
    try std.testing.expect(visited.contains(&C));
}

test "dfs cyclic graph" {
    const allocator = std.testing.allocator;
    var visited = HashSet(*Node).init(allocator);
    defer visited.deinit();

    // Create a cyclic graph A -> B -> C -> A
    var A = Node{ .nodes = &.{}, .value = 1 };
    var B = Node{ .nodes = &.{}, .value = 2 };
    var C = Node{ .nodes = &.{}, .value = 3 };

    // Set up connections
    var b_nodes = [_]*Node{&C};
    B.nodes = b_nodes[0..1];
    var a_nodes = [_]*Node{&B};
    A.nodes = (&a_nodes)[0..1];
    var c_nodes = [_]*Node{&A};
    C.nodes = c_nodes[0..1];

    try dfs(&A, &visited);

    try std.testing.expect(visited.contains(&A));
    try std.testing.expect(visited.contains(&B));
    try std.testing.expect(visited.contains(&C));
}

test "dfs tree structure" {
    const allocator = std.testing.allocator;
    var visited = HashSet(*Node).init(allocator);
    defer visited.deinit();

    // Create a tree:      A
    //                   / | \
    //                  B  C  D
    //                 /\    /\
    //                E  F  G  H
    var A = Node{ .nodes = &.{}, .value = 1 };
    var B = Node{ .nodes = &.{}, .value = 2 };
    var C = Node{ .nodes = &.{}, .value = 3 };
    var D = Node{ .nodes = &.{}, .value = 4 };
    var E = Node{ .nodes = &.{}, .value = 5 };
    var F = Node{ .nodes = &.{}, .value = 6 };
    var G = Node{ .nodes = &.{}, .value = 7 };
    var H = Node{ .nodes = &.{}, .value = 8 };

    // Set up leaf nodes (no children)

    // Set up middle tier
    var B_nodes = [_]*Node{ &E, &F };
    B.nodes = B_nodes[0..];

    var D_nodes = [_]*Node{ &G, &H };
    D.nodes = D_nodes[0..];

    // Set up root
    var A_nodes = [_]*Node{ &B, &C, &D };
    A.nodes = A_nodes[0..];

    try dfs(&A, &visited);

    // Check all nodes were visited
    try std.testing.expect(visited.contains(&A));
    try std.testing.expect(visited.contains(&B));
    try std.testing.expect(visited.contains(&C));
    try std.testing.expect(visited.contains(&D));
    try std.testing.expect(visited.contains(&E));
    try std.testing.expect(visited.contains(&F));
    try std.testing.expect(visited.contains(&G));
    try std.testing.expect(visited.contains(&H));
}

test "dfs single node" {
    const allocator = std.testing.allocator;
    var visited = HashSet(*Node).init(allocator);
    defer visited.deinit();

    var A = Node{ .nodes = &.{}, .value = 1 };

    try dfs(&A, &visited);

    try std.testing.expect(visited.contains(&A));
    try std.testing.expectEqual(visited.count(), 1);
}

test "dfs complex graph with multiple cycles" {
    const allocator = std.testing.allocator;
    var visited = HashSet(*Node).init(allocator);
    defer visited.deinit();

    // Create a complex graph with multiple cycles
    var A = Node{ .nodes = &.{}, .value = 1 };
    var B = Node{ .nodes = &.{}, .value = 2 };
    var C = Node{ .nodes = &.{}, .value = 3 };
    var D = Node{ .nodes = &.{}, .value = 4 };
    var E = Node{ .nodes = &.{}, .value = 5 };

    // A -> B -> C -> A (cycle 1)
    // A -> D -> E -> B (connects to cycle 1)
    // D -> A (second path to A)

    var C_nodes = [_]*Node{&A};
    C.nodes = C_nodes[0..];

    var B_nodes = [_]*Node{&C};
    B.nodes = B_nodes[0..];

    var E_nodes = [_]*Node{&B};
    E.nodes = E_nodes[0..];

    var D_nodes = [_]*Node{ &E, &A };
    D.nodes = D_nodes[0..];

    var A_nodes = [_]*Node{ &B, &D };
    A.nodes = A_nodes[0..];

    try dfs(&A, &visited);

    try std.testing.expect(visited.contains(&A));
    try std.testing.expect(visited.contains(&B));
    try std.testing.expect(visited.contains(&C));
    try std.testing.expect(visited.contains(&D));
    try std.testing.expect(visited.contains(&E));
}
