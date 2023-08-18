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
const IdentTok = lexer.Ident;

const Self = @This();

allocator: mem.Allocator,
ident: IdentTok,
args: std.ArrayList(Expr),
expr: *Expr,

fn deinitArgs(args: std.ArrayList(Expr)) void {
    for (args.items) |arg| {
        arg.deinit();
    }

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

fn parseArg(allocator: mem.Allocator, input: *[]const Token) !?Expr {
    const parsers = .{
        Ident.parse,
    };

    inline for (parsers) |parser| {
        switch (try parser(allocator, input)) {
            .ok => |x| return Expr.from(x),
            .err => |e| e.deinit(),
        }
    }

    return null;
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) !Result(Self) {
    var input_ = input.*;

    if (input_.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident, found nothing",
        )) };
    }

    const ident = switch (input_[0]) {
        .ident => |x| x,
        else => return .{ .err = Error.from(try InvalidInputError.init(
            allocator,
            "Expected Ident",
        )) },
    };

    input_ = input_[1..];

    var args = std.ArrayList(Expr).init(allocator);
    errdefer deinitArgs(args);

    while (try parseArg(allocator, &input_)) |arg| {
        try args.append(arg);
    }

    if (input_.len == 0) {
        deinitArgs(args);

        return .{ .err = Error.from(try InvalidInputError.init(
            allocator,
            "Expected '=', found nothing",
        )) };
    }

    {
        const found_eql = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, "="),
            else => false,
        };

        if (!found_eql) {
            for (args.items) |arg| {
                arg.deinit();
            }

            args.deinit();

            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected '='",
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

    if (input.len == 0) {
        deinitExpr(allocator, expr);
        deinitArgs(args);

        return .{ .err = Error.from(try InvalidInputError.init(
            allocator,
            "Expected ';', found nothing",
        )) };
    }

    {
        const found_semi = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, ";"),
            else => false,
        };

        if (!found_semi) {
            deinitExpr(allocator, expr);
            deinitArgs(args);

            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "expected ';'",
            )) };
        }

        input_ = input_[1..];
    }

    input.* = input_;

    return .{ .ok = .{
        .allocator = allocator,
        .ident = ident,
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

    try fmt.print(writer, "{s}Bind {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    ident: {s}\n", .{
        depth_tabs.items,
        self.ident.value,
    });

    try fmt.print(writer, "{s}    args: [\n", .{
        depth_tabs.items,
    });

    for (self.args.items) |arg| {
        try arg.format(allocator, writer, depth + 2);
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
