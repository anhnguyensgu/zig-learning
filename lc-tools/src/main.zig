//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");

const graphql = @import("graphql");
const lib = @import("lc_tools_lib");

const Render = @import("generator.zig").Generator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const renders = [_]Render{
        Render.new(allocator, "./templates/go/solution.go.tmpl", "solution"),
    };

    for (renders) |render| {
        try render.generate("example.go", "./output");
    }
}
