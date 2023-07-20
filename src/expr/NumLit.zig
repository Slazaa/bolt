const std = @import("std");

const ascii = std.ascii;
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

const Self = @This();

value: []const u8,

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    _ = allocator;

    if (input.len == 0) {
        return .{ .err = .invalid_input };
    }

    const literal = switch (input[0]) {
        .literal => |x| x,
        else => return .{ .err = .invalid_input },
    };

    for (literal.value) |c| {
        if (!ascii.isDigit(c)) {
            return .{ .err = .invalid_input };
        }
    }

    return .{ .ok = .{ input[1..], Self{ .value = literal.value } } };
}

pub fn format(self: Self, writer: fs.File.Writer, comptime depth: usize) FormatError!void {
    const depth_tabs = "    " ** depth;

    writer.print("{s}NumLit {{\n", .{depth_tabs}) catch return error.CouldNotFormat;
    writer.print("{s}    value: {s}\n", .{ depth_tabs, self.value }) catch return error.CouldNotFormat;
    writer.print("{s}}}\n", .{depth_tabs}) catch return error.CouldNotFormat;
}
