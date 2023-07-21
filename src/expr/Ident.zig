const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const Token = lexer.Token;
const Ident = lexer.Ident;

const ParserResult = parser.Result;

const FormatError = expr.FormatError;

const Self = @This();

value: Ident,

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    _ = allocator;

    var input_ = input;

    if (input_.len < 1) {
        return .{ .err = .invalid_input };
    }

    const value = switch (input_[0]) {
        .ident => |x| x,
        else => return .{ .err = .invalid_input },
    };

    input_ = input_[1..];

    return .{ .ok = .{ input, Self{ .value = value } } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}Ident {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    value: ", .{depth_tabs.items}) catch return error.CouldNotFormat;
    try self.value.format(writer);
    writer.print("\n", .{}) catch return error.CouldNotFormat;
    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
