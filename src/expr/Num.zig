const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const Self = @This();

value: []const u8,

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
) fmt.Error!void {
    _ = allocator;
    try fmt.print(writer, "Num {{\n", .{});

    try fmt.print(writer, "    value: {s}\n", .{
        self.value,
    });

    try fmt.print(writer, "}}\n", .{});
}
