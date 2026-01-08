const std = @import("std");
const zgrpc = @import("zgrpc");

pub fn main() !void {
    try startServer();
}

const ServerError = error{
    InitializationFailed,
    RuntimeError,
};

pub fn startServer() ServerError!void {
    const address = std.net.Address.parseIp("127.0.0.1", 8080) catch |e| {
        std.debug.print("Failed to parse address: {}\n", .{e});
        return ServerError.InitializationFailed;
    };

    var server = address.listen(.{}) catch |e| {
        std.debug.print("Failed to start server: {}\n", .{e});
        return ServerError.InitializationFailed;
    };

    while (true) {
        const conn = server.accept() catch |e| {
            std.debug.print("Failed to accept connection: {}\n", .{e});
            return ServerError.RuntimeError;
        };

        var buffer = [_]u8{0} ** 1024;
        while (true) {
            const received = conn.stream.read(buffer[0..]) catch |e| {
                std.debug.print("Failed to read from connection: {}\n", .{e});
                break;
            };
            if (received == 0) {
                break;
            }
            std.debug.print("Received data: {any}\n", .{buffer[0..received]});
        }
    }
}
