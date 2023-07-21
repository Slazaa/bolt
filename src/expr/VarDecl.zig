const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = expr.FormatError;

const Expr = expr.Expr;
const Ident = expr.Ident;

const Token = lexer.Token;

const ParserResult = parser.Result;

const Self = @This();

allocator: mem.Allocator,
ident: Ident,
mut: bool,
expr: ?*Expr,

pub fn deinit(self: *Self) void {
    if (self.expr) |e| {
        self.allocator.destroy(e);
    }
}

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    if (input_.len < 3) {
        return .{ .err = .invalid_input };
    }

    switch (input_[0]) {
        .keyword => |x| if (!mem.eql(u8, x.value, "let")) return .{ .err = .invalid_input },
        else => {},
    }

    input_ = input_[1..];

    const mut = b: {
        switch (input_[0]) {
            .keyword => |x| {
                if (!mem.eql(u8, x.value, "mut")) return .{ .err = .invalid_input };
                break :b true;
            },
            else => break :b false,
        }
    };

    if (mut) {
        input_ = input_[1..];
    }

    const res = switch (Ident.parse(allocator, input_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    input_ = res[0];
    const ident = res[1];

    switch (input[0]) {
        .punct => |x| if (!mem.eql(u8, x.value, ";")) return .{ .err = .invalid_input },
        else => {},
    }

    input_ = input_[1..];

    return .{ .ok = .{ input_, Self{
        .allocator = allocator,
        .ident = ident,
        .mut = mut,
        .expr = null,
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
    writer.print("{s}    mut: {}\n", .{ depth_tabs.items, self.mut }) catch return error.CouldNotFormat;

    if (self.expr) |e| {
        writer.print("{s}    expr:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
        try e.format(allocator, writer, depth + 2);
    } else {
        writer.print("{s}    expr: null\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    }

    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
