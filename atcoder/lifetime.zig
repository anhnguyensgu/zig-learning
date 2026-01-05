const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var service = Service{ .allocator = allocator };
    defer service.deinit();
    service.hello();
    var a = Repository{ .id = 4 };
    service.add(&a);
    service.hello();
}

const Service = struct {
    repository: std.ArrayList(*Repository) = .{},
    allocator: std.mem.Allocator,

    pub fn hello(self: *Service) void {
        for (self.repository.items) |repo| {
            var a = repo;
            a.hello();
        }
    }

    pub fn add(self: *Service, repo: *Repository) void {
        self.repository.append(self.allocator, repo) catch {};
    }

    pub fn deinit(self: *Service) void {
        self.repository.deinit(self.allocator);
    }
};
const Repository = struct {
    id: i32,
    pub fn hello(self: *Repository) void {
        std.debug.print("hello {}\n", .{self.id});
    }
};
