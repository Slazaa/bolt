const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const fmt = @import("fmt.zig");

const Writer = fs.File.Writer;

const Self = @This();

line: usize,
column: usize,
index: usize,

pub fn default() Self {
    return Self{
        .line = 1,
        .column = 1,
        .index = 0,
    };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
    depth: usize,
) fmt.Error!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    try fmt.addDepth(&depth_tabs, depth);

    try fmt.print(writer, "{s}Position: {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    line: {}\n", .{
        depth_tabs.items,
        self.line,
    });

    try fmt.print(writer, "{s}    column: {}\n", .{
        depth_tabs.items,
        self.column,
    });

    try fmt.print(writer, "{s}    index: {}\n", .{
        depth_tabs.items,
        self.index,
    });

    try fmt.print(writer, "{s}}}\n", .{
        depth_tabs.items,
    });
}
