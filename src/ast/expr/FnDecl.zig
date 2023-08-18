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

const Token = lexer.Token;
const IdentTok = lexer.Ident;

const Self = @This();

allocator: mem.Allocator,
args: std.ArrayList(IdentTok),
expr: *Expr,

fn deinitArgs(args: std.ArrayList(IdentTok)) void {
    args.deinit();
}

fn deinitExpr(allocator: mem.Allocator, expr: *Expr) void {
    expr.deinit();
    allocator.destroy(expr);
}

pub fn deinit(self: Self) void {
    deinitArgs(self.args);
    deinitExpr(self.allocator, self.expr);
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) anyerror!Result(Self) {
    var input_ = input.*;

    var args = std.ArrayList(IdentTok).init(allocator);
    errdefer deinitArgs(args);

    while (input_.len != 0) {
        const arg = switch (input_[0]) {
            .ident => |x| x,
            else => break,
        };

        try args.append(arg);

        input_ = input_[1..];
    }

    if (args.items.len == 0) {
        deinitArgs(args);

        return .{ .err = Error.from(try InvalidInputError.init(
            allocator,
            "Expected at least 1 arg, found nothing",
        )) };
    }

    if (input_.len == 0) {
        deinitArgs(args);

        return .{ .err = Error.from(try InvalidInputError.init(
            allocator,
            "Expected '->', found nothing",
        )) };
    }

    {
        const found_arr = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, "->"),
            else => false,
        };

        if (!found_arr) {
            deinitArgs(args);

            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected '->'",
            )) };
        }

        input_ = input_[1..];
    }

    const expr = try allocator.create(Expr);

    expr.* = switch (try Expr.parse(allocator, &input_)) {
        .ok => |x| x,
        .err => |e| {
            allocator.destroy(expr);
            deinitArgs(args);

            return .{ .err = e };
        },
    };

    errdefer deinitExpr(allocator, expr);

    input.* = input_;

    return .{ .ok = .{
        .allocator = allocator,
        .args = args,
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
