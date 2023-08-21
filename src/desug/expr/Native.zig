const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const eval = @import("../../eval.zig");
const expr = @import("../../expr.zig");

const Expr = expr.Expr;

const Result = eval.Result;

const Scope = eval.Scope;

const Self = @This();

func: *const fn (mem.Allocator, Scope) anyerror!Result(Expr),

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
    depth: usize,
) fmt.Error!void {
    _ = self;

    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    try fmt.addDepth(&depth_tabs, depth);

    try fmt.print(writer, "{s}Native {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    func: [fn]\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
