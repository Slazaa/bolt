const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const desug = @import("../desug.zig");
const lexer = @import("../lexer.zig");

const IdentTok = lexer.Ident;

const AstExpr = desug.expr.Expr;

const Self = @This();

arg: IdentTok,
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
    replaceArgWithExpr(&self.expr, self.arg.value, expr);
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
) fmt.Error!void {
    try fmt.print(writer, "Fn {{\n", .{});

    try fmt.print(writer, "    arg: {s}\n", .{
        self.arg.value,
    });

    try fmt.print(writer, "    expr:\n", .{});

    try self.expr.format(allocator, writer, 2);

    try fmt.print(writer, "}}\n", .{});
}
