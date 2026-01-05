const std = @import("std");
const net = std.net;
const mem = std.mem;

pub fn main() !void {
    const address = net.Address.parseIp("127.0.0.1", 8080) catch unreachable;
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    std.log.info("🚀 Blog server running at http://localhost:8080", .{});
    std.log.info("Press Ctrl+C to stop", .{});

    while (true) {
        const connection = server.accept() catch |err| {
            std.log.err("Connection error: {}", .{err});
            continue;
        };
        handleConnection(connection) catch |err| {
            std.log.err("Request error: {}", .{err});
        };
    }
}

fn handleConnection(connection: net.Server.Connection) !void {
    defer connection.stream.close();

    var buffer: [4096]u8 = undefined;
    const bytes_read = connection.stream.read(&buffer) catch return;
    if (bytes_read == 0) return;

    const path = parsePath(buffer[0..bytes_read]) orelse "/";
    const response = route(path);

    _ = connection.stream.write(response.headers) catch return;
    _ = connection.stream.write(response.body) catch return;
}

const Response = struct { headers: []const u8, body: []const u8 };

fn route(path: []const u8) Response {
    // Static pages
    if (mem.eql(u8, path, "/")) return html(page_index);
    if (mem.eql(u8, path, "/posts")) return html(page_posts);
    if (mem.eql(u8, path, "/about")) return html(page_about);
    if (mem.eql(u8, path, "/static/css/style.css")) return css(file_css);

    // Blog posts
    if (mem.startsWith(u8, path, "/posts/")) {
        const slug = path[7..];
        if (mem.eql(u8, slug, "welcome-to-zig-blog")) return html(post_welcome);
        if (mem.eql(u8, slug, "building-web-servers-zig")) return html(post_servers);
        if (mem.eql(u8, slug, "memory-management-zig")) return html(post_memory);
    }

    return .{ .headers = http_404, .body = page_404 };
}

fn html(body: []const u8) Response {
    return .{ .headers = http_html, .body = body };
}

fn css(body: []const u8) Response {
    return .{ .headers = http_css, .body = body };
}

fn parsePath(request: []const u8) ?[]const u8 {
    const line_end = mem.indexOf(u8, request, "\r\n") orelse return null;
    var parts = mem.splitScalar(u8, request[0..line_end], ' ');
    _ = parts.next();
    return parts.next();
}

// HTTP headers
const http_html = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\n\r\n";
const http_css = "HTTP/1.1 200 OK\r\nContent-Type: text/css\r\nConnection: close\r\n\r\n";
const http_404 = "HTTP/1.1 404 Not Found\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\n\r\n";

// Embedded files
const page_index = @embedFile("static/html/index.html");
const page_posts = @embedFile("static/html/posts.html");
const page_about = @embedFile("static/html/about.html");
const page_404 = @embedFile("static/html/404.html");
const file_css = @embedFile("static/css/style.css");

// Blog posts
const post_welcome = @embedFile("static/html/posts/welcome-to-zig-blog.html");
const post_servers = @embedFile("static/html/posts/building-web-servers-zig.html");
const post_memory = @embedFile("static/html/posts/memory-management-zig.html");
