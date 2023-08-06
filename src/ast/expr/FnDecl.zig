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
args: std.ArrayList(Ident),
expr: *Expr,

pub fn deinit(self: Self) void {
    self.args.deinit();

    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    var input_ = input.*;

    var args = std.ArrayList(Ident).init(allocator);

    while (true) {
        if (input_.len == 0) {
            break;
        }

        const arg = switch (input_[0]) {
            .ident => |x| x,
            else => break,
        };

        args.append(arg) catch {
            args.deinit();
            @panic("Allocation failed");
        };

        input_ = input_[1..];
    }

    if (args.items.len == 0) {
        args.deinit();

        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected at least 1 arg, found nothing",
        )) };
    }

    if (input_.len == 0) {
        args.deinit();

        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected '->', found nothing",
        )) };
    }

    switch (input_[0]) {
        .punct => |x| if (!mem.eql(u8, x.value, "->")) {
            args.deinit();

            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected '->'",
            )) };
        },
        else => {
            args.deinit();

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
            .err => |e| {
                args.deinit();
                return .{ .err = e };
            },
        };

        const expr_ = allocator.create(Expr) catch @panic("Allocation failed");
        expr_.* = res;

        break :b expr_;
    };

    input.* = input_;

    return .{ .ok = .{
        .allocator = allocator,
        .args = args,
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

    try fmt.print(writer, "{s}    args: [\n", .{
        depth_tabs.items,
    });

    for (self.args.items) |arg| {
        try fmt.print(writer, "{s}        {s}\n", .{
            depth_tabs.items,
            arg.value,
        });
    }

    try fmt.print(writer, "{s}    ]\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
