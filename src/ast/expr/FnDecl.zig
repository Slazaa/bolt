const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");
const expr = ast.expr;

const Error = ast.Error;
const Result = ast.Result;
const InvalidInputError = ast.InvalidInputError;

const Expr = expr.Expr;

const Token = lexer.Token;
const Ident = lexer.Ident;

const Self = @This();

allocator: mem.Allocator,
arg: Ident,
expr: *Expr,

pub fn deinit(self: Self) void {
    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    var input_ = input.*;

    if (input_.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident, found nothing",
        )) };
    }

    const arg = switch (input_[0]) {
        .ident => |x| x,
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident",
        )) },
    };

    input_ = input_[1..];

    if (input_.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected '->', found nothing",
        )) };
    }

    switch (input_[0]) {
        .punct => |x| if (!mem.eql(u8, x.value, "->")) {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected '->'",
            )) };
        },
        else => {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected '->'",
            )) };
        },
    }

    input_ = input_[1..];

    const expr_ = b: {
        const res = switch (Expr.parse(allocator, &input_)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        const expr_ = allocator.create(Expr) catch @panic("Allocation failed");
        expr_.* = res;

        break :b expr_;
    };

    input.* = input_;

    return .{ .ok = .{
        .allocator = allocator,
        .arg = arg,
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

    try fmt.print(writer, "{s}FnDecl: {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    arg: {s}\n", .{
        depth_tabs.items,
        self.arg.value,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
