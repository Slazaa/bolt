const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");
const expr = ast.expr;

const Error = ast.Error;
const Result = ast.Result;
const InvalidInputError = ast.InvalidInputError;

const Expr = expr.Expr;
const Ident = expr.Ident;

const Token = lexer.Token;
const IdentTok = lexer.Ident;

const Self = @This();

allocator: mem.Allocator,
ident: IdentTok,
args: std.ArrayList(Expr),
expr: *Expr,

pub fn deinit(self: Self) void {
    for (self.args.items) |arg| {
        arg.deinit();
    }

    self.args.deinit();

    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    var input_ = input.*;

    const ident = switch (input_[0]) {
        .ident => |x| x,
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident",
        )) },
    };

    input_ = input_[1..];

    var args = std.ArrayList(Expr).init(allocator);

    const parsers = .{
        Ident.parse,
    };

    while (true) {
        const res = inline for (parsers) |parser| {
            switch (parser(allocator, &input_)) {
                .ok => |x| break Expr.from(x),
                .err => |e| e.deinit(),
            }
        } else {
            break;
        };

        args.append(res) catch {
            args.deinit();
            @panic("Allocation failed");
        };
    }

    if (input_.len == 0) {
        args.deinit();

        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected '=', found nothing",
        )) };
    }

    switch (input_[0]) {
        .punct => |x| {
            if (!mem.eql(u8, x.value, "=")) {
                args.deinit();

                return .{ .err = Error.from(InvalidInputError.init(
                    allocator,
                    "Expected '='",
                )) };
            }

            input_ = input_[1..];
        },
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected '='",
        )) },
    }

    const expr_ = b: {
        const res = switch (Expr.parse(allocator, &input_)) {
            .ok => |x| x,
            .err => |e| {
                args.deinit();
                return .{ .err = e };
            },
        };

        const expr_ = allocator.create(Expr) catch {
            args.deinit();
            @panic("Allocation failed");
        };

        expr_.* = res;

        break :b expr_;
    };

    if (input.len == 0) {
        allocator.destroy(expr_);
        args.deinit();

        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected ';', found nothing",
        )) };
    }

    switch (input_[0]) {
        .punct => |x| {
            if (!mem.eql(u8, x.value, ";")) {
                allocator.destroy(expr_);
                args.deinit();

                return .{ .err = Error.from(InvalidInputError.init(
                    allocator,
                    "Expected ';'",
                )) };
            }
        },
        else => {
            allocator.destroy(expr_);
            args.deinit();

            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected ';'",
            )) };
        },
    }

    input_ = input_[1..];

    input.* = input_;

    return .{ .ok = .{
        .allocator = allocator,
        .ident = ident,
        .args = args,
        .expr = expr_,
    } };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: fs.File.Writer,
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
