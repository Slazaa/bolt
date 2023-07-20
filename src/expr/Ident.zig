const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.ForamtError;

const Token = lexer.Token;
const Ident = lexer.Ident;

const ParserResult = parser.Result;

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

pub fn format(self: Self, writer: fs.File.Writer, depth: usize) FormatError!void {
    const depth_tabs = "    " ** depth;

    writer.print("{s}Ident {{\n", .{depth_tabs}) catch return error.CouldNotFormat;
    writer.print("{s}    value: ", .{depth_tabs}) catch return error.CouldNotFormat;
    try self.value.format(writer);
    writer.print("\n", .{});
    writer.print("{s}}}\n", .{depth_tabs}) catch return error.CouldNotFormat;
}
