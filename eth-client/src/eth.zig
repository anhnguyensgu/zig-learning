const std = @import("std");
const writer = std.io.getStdOut().writer();
pub const add = @import("utils/math.zig").add;

pub const EthereumClient = struct {
    rpc_url: []const u8,
    client: *std.http.Client,
    allocator: std.mem.Allocator,

    pub fn create(self: *const EthereumClient) !PostResponse {
        return self.call();
    }

    fn call(self: *const EthereumClient) !PostResponse {
        std.debug.print("Calling Ethereum Client with URL: {s}\n", .{self.rpc_url});
        const reqBody = PostRequest{
            .userId = 1,
            .title = "foo",
            .body = "bar",
        };
        return self.execute(&reqBody);
    }

    fn execute(self: *const EthereumClient, reqBody: *const PostRequest) !PostResponse {
        var response_body = std.ArrayList(u8).init(self.allocator);
        var buf = std.ArrayList(u8).init(self.allocator);
        try std.json.stringify(reqBody, .{}, buf.writer());
        const body = buf.items;

        const headers = &[_]std.http.Header{
            .{ .name = "Content-Type", .value = "application/json" },
        };
        var client = self.client;
        const url = self.rpc_url;

        const response = try client.fetch(.{ .method = .POST, .payload = body, .location = .{ .url = url }, .extra_headers = headers, .response_storage = .{ .dynamic = &response_body } });
        try writer.print("Response Status: {d}\n Response Body:{s}\n", .{ response.status, response_body.items });
        const result = try std.json.parseFromSlice(PostResponse, self.allocator, response_body.items, .{ .ignore_unknown_fields = true });
        return result.value;
    }
};

pub const PostRequest = struct {
    userId: i32,
    title: []const u8,
    body: []const u8,
};

pub const PostResponse = struct {
    userId: i32,
    id: i32,
    title: []u8,
    body: []u8,
};

fn execute(comptime T: type, req: *const T) !Response(T) {
    return Response(T){
        .status = 200,
        .body = req.*,
    };
}

pub fn Response(comptime T: type) type {
    return struct {
        status: i32,
        body: T,
    };
}
