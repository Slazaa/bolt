const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const desug = @import("../desug.zig");
const lexer = @import("../lexer.zig");

const AstExpr = desug.expr.Expr;

const Self = @This();

arg: []const u8,
expr: AstExpr,

fn replaceArgWithExpr(expr: *AstExpr, arg: []const u8, value: AstExpr) void {
    switch (expr.*) {
        .fn_call => |x| {
            replaceArgWithExpr(x.func, arg, value);
            replaceArgWithExpr(x.expr, arg, value);
        },
        .fn_decl => |x| replaceArgWithExpr(x.expr, arg, value),
        .ident => |x| if (mem.eql(u8, x.value.value, arg)) {
            expr.* = value;
        },
        else => {},
    }
}

pub fn replaceArg(self: *Self, expr: AstExpr) void {
    replaceArgWithExpr(&self.expr, self.arg, expr);
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

    try fmt.print(writer, "{s}Fn {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    arg: {s}\n", .{
        depth_tabs.items,
        self.arg,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, 2);

    try fmt.print(writer, "{s}}}\n", .{
        depth_tabs.items,
    });
}
