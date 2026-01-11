const std = @import("std");
const Node = @import("node.zig").Node;
const CreateNode = @import("node.zig").CreateNode;
const Signer = @import("node.zig").Signer;

pub fn main() !void {
    const SimpleNode = CreateNode(Signer);
    const node = SimpleNode.load_from();
    const a = &node;
    a.run();
}
