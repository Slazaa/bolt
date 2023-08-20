const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const Expr = @import("../../expr.zig").Expr;

const Self = @This();

allocator: mem.Allocator,
name: []const u8,
expr: *Expr,

pub fn init(allocator: mem.Allocator, name: []const u8, expr: Expr) Self {
    var expr_ = allocator.create(Expr);
    expr_.* = expr;

    return .{
        .allocator = allocator,
        .name = name,
        .expr = expr_,
    };
}

pub fn deinit(self: Self) void {
    self.allocator.destroy(self.expr);
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

    try fmt.print(writer, "{s}Builtin {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    name: {s}\n", .{
        depth_tabs.items,
        self.name,
    });

    try fmt.print(writer, "{s}    expr:", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
