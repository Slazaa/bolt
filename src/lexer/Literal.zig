const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;

const Self = @This();

value: []const u8,

pub fn lex(input: []const u8) ParserResult([]const u8, Self) {
    var input_ = input;

    if (input.len == 0 or !ascii.isDigit(input_[0])) {
        return .{ .err = .invalid_input };
    }

    input_ = input_[1..];

    while (input_.len != 0 and ascii.isDigit(input_[0])) {
        input_ = input_[1..];
    }

    return .{ .ok = .{ input_, Self{ .value = input[0 .. input.len - input_.len] } } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Literal | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
