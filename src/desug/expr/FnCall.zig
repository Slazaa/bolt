const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const ast = @import("../../ast.zig");
const expr = @import("../expr.zig");

const AstFnCall = ast.expr.FnCall;

const Expr = expr.Expr;

const Self = @This();

allocator: mem.Allocator,
func: *Expr,
expr: *Expr,

pub fn deinit(self: Self) void {
    self.func.deinit();
    self.allocator.destroy(self.func);

    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn desug(allocator: mem.Allocator, fn_call: AstFnCall) !Self {
    const func = try allocator.create(Expr);
    func.* = try Expr.desug(allocator, fn_call.func.*);

    const expr_ = try allocator.create(Expr);
    expr_.* = try Expr.desug(allocator, fn_call.expr.*);

    return .{
        .allocator = allocator,
        .func = func,
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
