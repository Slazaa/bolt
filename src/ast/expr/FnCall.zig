const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const Error = ast.Error;
const Result = ast.Result;
const InvalidInputError = ast.InvalidInputError;

const Expr = ast.expr.Expr;
const Ident = ast.expr.Ident;

const Token = lexer.Token;

const Self = @This();

allocator: mem.Allocator,
func: *Expr,
expr: *Expr,

fn deinitFunc(allocator: mem.Allocator, func: *Expr) void {
    func.deinit();
    allocator.destroy(func);
}

fn deinitExpr(allocator: mem.Allocator, expr: *Expr) void {
    expr.deinit();
    allocator.destroy(expr);
}

pub fn deinit(self: Self) void {
    deinitFunc(self.allocator, self.func);
    deinitExpr(self.allocator, self.expr);
}

pub fn parse(allocator: mem.Allocator, func: Expr, expr: Expr) !Result(Self) {
    const func_ = try allocator.create(Expr);
    func_.* = func;

    errdefer deinitFunc(allocator, func_);

    const expr_ = try allocator.create(Expr);
    expr_.* = expr;

    errdefer deinitExpr(allocator, expr_);

    return .{ .ok = .{
        .allocator = allocator,
        .func = func_,
        .expr = expr_,
    } };
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

    try fmt.print(writer, "{s}FnCall {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    func:\n", .{
        depth_tabs.items,
    });

    try self.func.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
