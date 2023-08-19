const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const ast = @import("../../ast.zig");
const lexer = @import("../../lexer.zig");

const AstBind = ast.expr.Bind;

const IdentTok = lexer.Ident;

const expr = @import("../expr.zig");

const Expr = expr.Expr;

const Self = @This();

allocator: mem.Allocator,
ident: IdentTok,
expr: *Expr,

pub fn deinit(self: Self) void {
    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn desug(allocator: mem.Allocator, bind: AstBind) anyerror!Self {
    const expr_ = try allocator.create(Expr);
    expr_.* = try Expr.desug(allocator, bind.expr.*);

    return .{
        .allocator = allocator,
        .ident = bind.ident,
        .expr = expr_,
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

    try fmt.print(writer, "{s}Bind {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    ident: {s}\n", .{
        depth_tabs.items,
        self.ident.value,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
