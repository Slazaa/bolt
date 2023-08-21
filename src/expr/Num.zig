const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const Self = @This();

allocator: mem.Allocator,
value: std.ArrayList(u8),

pub fn deinit(self: Self) void {
    self.value.deinit();
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

    try fmt.print(writer, "Num {{\n", .{});

    try fmt.print(writer, "    value: {s}\n", .{
        self.value.items,
    });

    try fmt.print(writer, "}}\n", .{});
}
