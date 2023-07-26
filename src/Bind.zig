const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

const FormatError = @import("expr.zig").FormatError;

const Expr = @import("expr.zig").Expr;
const Ident = @import("expr.zig").Ident;

const Token = lexer.Token;

const ParserResult = parser.Result;

const Self = @This();

allocator: mem.Allocator,
ident: Ident,
args: std.ArrayList(Expr),
expr: ?*Expr,

pub fn deinit(self: Self) void {
    self.args.deinit();

    if (self.expr) |expr| {
        expr.deinit();
        self.allocator.destroy(expr);
    }
}

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    const ident = b: {
        const res = switch (Ident.parse(allocator, input_)) {
            .ok => |x| x,
            .err => return .{ .err = .invalid_input },
        };

        input_ = res[0];

        break :b res[1];
    };

    var args = std.ArrayList(Expr).init(allocator);

    while (true) {
        const res = switch (Expr.parse(allocator, input_)) {
            .ok => |x| x,
            .err => break,
        };

        input_ = res[0];

        args.append(res[1]) catch {
            args.deinit();
            return .{ .err = .invalid_input };
        };
    }

    if (input_.len == 0) {
        args.deinit();
        return .{ .err = .invalid_input };
    }

    switch (input_[0]) {
        .punct => |x| {
            if (!mem.eql(u8, x.value, "=")) {
                args.deinit();
                return .{ .err = .invalid_input };
            }

            input_ = input_[1..];
        },
        else => {
            args.deinit();
            return .{ .err = .invalid_input };
        },
    }

    const expr = b: {
        const res = switch (Expr.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| {
                args.deinit();
                return .{ .err = e };
            },
        };

        input_ = res[0];

        const expr = allocator.create(Expr) catch {
            args.deinit();
            return .{ .err = .invalid_input };
        };

        expr.* = res[1];

        break :b expr;
    };

    switch (input_[0]) {
        .punct => |x| {
            if (!mem.eql(u8, x.value, ";")) {
                args.deinit();
                return .{ .err = .invalid_input };
            }
        },
        else => {
            args.deinit();
            return .{ .err = .invalid_input };
        },
    }

    input_ = input_[1..];

    return .{ .ok = .{ input_, Self{
        .allocator = allocator,
        .ident = ident,
        .args = args,
        .expr = expr,
    } } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}Bind {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    ident:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    try self.ident.format(allocator, writer, depth + 2);
    writer.print("{s}    args: [\n", .{depth_tabs.items}) catch return error.CouldNotFormat;

    for (self.args.items) |arg| {
        try arg.format(allocator, writer, depth + 2);
    }

    writer.print("{s}    ]\n", .{depth_tabs.items}) catch return error.CouldNotFormat;

    if (self.expr) |expr| {
        writer.print("{s}    expr:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
        try expr.format(allocator, writer, depth + 2);
    } else {
        writer.print("{s}    expr: null\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    }

    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
