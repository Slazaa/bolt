const std = @import("std");

const fs = std.fs;
const heap = std.heap;
const io = std.io;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = expr.FormatError;

const Token = lexer.Token;

const Literal = lexer.Literal;

const ParserResult = parser.Result;

const digit1 = parser.digit1;

const Self = @This();

value: []const u8,

pub fn parse(input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    if (input_.len == 0) {
        return .{ .err = .invalid_input };
    }

    const literal = switch (input_[0]) {
        .literal => |x| x,
        else => return .{ .err = .invalid_input },
    };

    const res = switch (digit1(literal.value)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    input_ = res[0];
    const value = res[1];

    return .{ .ok = .{ input_, Self{
        .value = value,
    } } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}NumLit {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    value: {s}\n", .{ depth_tabs.items, self.value }) catch return error.CouldNotFormat;
    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
