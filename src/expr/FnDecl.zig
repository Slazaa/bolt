const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = @import("../expr.zig").FormatError;

const Expr = @import("../expr.zig").Expr;
const Ident = @import("../expr.zig").Ident;

const Token = lexer.Token;

const ParserResult = parser.Result;

const Self = @This();

allocator: mem.Allocator,
ident: Ident,
params: std.ArrayList(Expr),
expr: ?*Expr,

pub fn deinit(self: Self) void {
    self.params.deinit();

    if (self.expr) |e| {
        e.deinit();
        self.allocator.destroy(e);
    }
}

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    switch (input_[0]) {
        .keyword => |x| if (!mem.eql(u8, x.value, "let")) return .{ .err = .invalid_input },
        else => {},
    }

    input_ = input_[1..];

    const ident = b: {
        const res = switch (Ident.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        input_ = res[0];

        break :b res[1];
    };

    const expr = b: {
        switch (input_[0]) {
            .punct => |x| {
                if (!mem.eql(u8, x.value, "=")) {
                    break :b null;
                }

                input_ = input_[1..];
            },
            else => break :b null,
        }

        const res = switch (Expr.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        input_ = res[0];

        const expr = allocator.create(Expr) catch return .{ .err = .invalid_input };
        expr.* = res[1];

        break :b expr;
    };

    return .{ .ok = .{ input_, Self{
        .allocator = allocator,
        .ident = ident,
        .params = std.ArrayList(Expr).init(allocator),
        .expr = expr,
    } } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}VarDecl {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    ident:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    try self.ident.format(allocator, writer, depth + 2);

    if (self.expr) |e| {
        writer.print("{s}    expr:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
        try e.format(allocator, writer, depth + 2);
    } else {
        writer.print("{s}    expr: null\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    }

    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
