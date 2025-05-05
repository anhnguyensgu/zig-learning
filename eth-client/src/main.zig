//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const eth = @import("eth.zig");
const EthereumClient = @import("eth.zig").EthereumClient;

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
pub fn main() !void {
    const al = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(al);
    const allocator = arena.allocator();
    defer arena.deinit();

    var httpClient = std.http.Client{ .allocator = allocator };
    const eth_client = EthereumClient{
        .rpc_url = "https://jsonplaceholder.typicode.com/posts",
        .client = &httpClient,
        .allocator = allocator,
    };

    const result = try eth_client.create();
    std.debug.print("Ethereum Client Result: {d}\n", .{result.id});
    _ = eth.add(1, 2);
}
