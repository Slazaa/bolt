const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const ast = @import("../../ast.zig");

const File = ast.expr.File;

const Bind = @import("Bind.zig");

const Self = @This();

binds: std.ArrayList(Bind),

pub fn deinit(self: Self) void {
    for (self.binds.items) |bind| {
        bind.deinit();
    }

    self.binds.deinit();
}

pub fn desug(allocator: mem.Allocator, file: File) !Self {
    var binds = try std.ArrayList(Bind).initCapacity(
        allocator,
        file.binds.items.len,
    );

    for (file.binds.items) |bind| {
        try binds.append(try Bind.desug(allocator, bind));
    }

    return .{
        .binds = binds,
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

    try fmt.print(writer, "{s}File {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    binds: [\n", .{
        depth_tabs.items,
    });

    for (self.binds.items) |bind| {
        try bind.format(allocator, writer, depth + 2);
    }

    try fmt.print(writer, "{s}    ]\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
