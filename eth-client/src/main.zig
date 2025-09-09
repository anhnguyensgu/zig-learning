//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const zap = @import("root.zig").zap;
// const eth = @import("eth.zig");
// const EthereumClient = @import("eth.zig").EthereumClient;
fn onRequest(r: zap.Request) !void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = onRequest,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
// /// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
// pub fn main() !void {
//     const al = std.heap.page_allocator;
//     var arena = std.heap.ArenaAllocator.init(al);
//     const allocator = arena.allocator();
//     defer arena.deinit();
//
//     var httpClient = std.http.Client{ .allocator = allocator };
//     const eth_client = EthereumClient{
//         .rpc_url = "https://jsonplaceholder.typicode.com/posts",
//         .client = &httpClient,
//         .allocator = allocator,
//     };
//
//     const result = try eth_client.create();
//     std.debug.print("Ethereum Client Result: {d}\n", .{result.id});
//     _ = eth.add(1, 2);
// }
