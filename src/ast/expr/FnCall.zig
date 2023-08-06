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
const Ident = expr.Ident;

const Token = lexer.Token;
const IdentTok = lexer.Ident;

const Self = @This();

ident: IdentTok,
args: std.ArrayList(Expr),

pub fn deinit(self: Self) void {
    self.args.deinit();
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    var input_ = input.*;

    if (input_.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident, found nothing",
        )) };
    }

    const ident = switch (input_[0]) {
        .ident => |x| x,
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident",
        )) },
    };

    input_ = input_[1..];

    const parsers = .{
        Ident.parse,
        Expr.parse,
    };

    var args = std.ArrayList(Expr).init(allocator);

    while (true) {
        const arg = inline for (parsers) |parser| {
            switch (parser(allocator, &input_)) {
                .ok => |x| break switch (@TypeOf(x)) {
                    Expr => x,
                    else => Expr.from(x),
                },
                .err => |e| e.deinit(),
            }
        } else {
            break;
        };

        args.append(arg) catch {
            args.deinit();
            @panic("Allocation failed");
        };
    }

    if (args.items.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected at least 1args, found nothing",
        )) };
    }

    input.* = input_;

    return .{ .ok = .{
        .ident = ident,
        .args = args,
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

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
