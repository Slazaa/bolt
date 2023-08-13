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

pub fn deinit(self: Self) void {
    self.func.deinit();
    self.allocator.destroy(self.func);

    self.expr.deinit();
    self.allocator.destroy(self.func);
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    var input_ = input.*;

    // const func = allocator.create(Expr) catch @panic("Allocation failed");

    // func.* = Expr.from(switch (Ident.parse(allocator, &input_)) {
    //     .ok => |x| x,
    //     .err => |e| {
    //         allocator.destroy(func);
    //         return .{ .err = e };
    //     },
    // });

    // const expr_ = allocator.create(Expr) catch {
    //     func.deinit();
    //     allocator.destroy(func);

    //     @panic("Allocation failed");
    // };

    // expr_.* = Expr.from(switch (Ident.parse(allocator, &input_)) {
    //     .ok => |x| x,
    //     .err => |e| {
    //         allocator.destroy(expr_);

    //         func.deinit();
    //         allocator.destroy(func);

    //         return .{ .err = e };
    //     },
    // });

    input.* = input_;

    return .{ .ok = .{
        .allocator = allocator,
        .func = func,
        .expr = expr,
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
