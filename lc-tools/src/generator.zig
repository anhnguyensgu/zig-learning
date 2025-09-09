const std = @import("std");

pub const Generator = struct {
    renderName: []const u8,
    templatePath: []const u8,
    allocator: std.mem.Allocator,

    pub fn new(
        allocator: std.mem.Allocator,
        templatePath: []const u8,
        renderName: []const u8,
    ) Generator {
        return Generator{
            .renderName = renderName,
            .templatePath = templatePath,
            .allocator = allocator,
        };
    }

    pub fn generate(self: Generator, name: []const u8, basePath: []const u8) !void {
        // handle error
        const templateBytes = try std.fs.cwd().readFileAlloc(self.allocator, self.templatePath, 10 * 1024);
        defer self.allocator.free(templateBytes);

        // Implement a simple template replacement for runtime string
        const rendered = try replaceTemplate(self.allocator, templateBytes, self.renderName);
        defer self.allocator.free(rendered);

        try std.fs.cwd().makePath(basePath);
        //join basePath and name to create output
        const outputPath = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ basePath, name });
        defer self.allocator.free(outputPath);

        std.log.info("Output path: {s}", .{outputPath});
        const file = try std.fs.cwd().createFile(outputPath, .{});
        defer file.close();

        try file.writeAll(rendered);

        std.log.info("Component {s} rendering template at: {s}", .{ self.renderName, self.templatePath });
    }
};

fn replaceTemplate(allocator: std.mem.Allocator, template: []const u8, name: []const u8) ![]const u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();

    var i: usize = 0;
    while (i < template.len) {
        // Check for {{name}} pattern
        if (i + 8 <= template.len and std.mem.eql(u8, template[i .. i + 8], "{{name}}")) {
            try output.appendSlice(name);
            i += 8;
        } else {
            try output.append(template[i]);
            i += 1;
        }
    }

    return output.toOwnedSlice();
}
