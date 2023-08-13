const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const desug = @import("../desug.zig");
const lexer = @import("../lexer.zig");

const IdentTok = lexer.Ident;

const Expr = desug.expr.Expr;

const Self = @This();

arg: IdentTok,
expr: Expr,

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
) fmt.Error!void {
    try fmt.print(writer, "Fn {{\n", .{});

    try fmt.print(writer, "    arg: {s}", .{
        self.arg.value,
    });

    try fmt.print(writer, "    expr:\n", .{});

    try self.expr.format(allocator, writer, 2);

    try fmt.print(writer, "}}\n", .{});
}
