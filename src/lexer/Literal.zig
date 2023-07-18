const std = @import("std");

const fs = std.fs;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;
const Parser = parser.Parser;

const digit1 = @import("../parser.zig").digit1;

const Self = @This();

value: []const u8,

pub fn lex(input: []const u8) ParserResult([]const u8, Self) {
    var input_ = input;

    const res = switch (digit1(input_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    input_ = res[0];
    const value = res[1];

    return .{ .ok = .{ input_, Self{
        .value = value,
    } } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Literal | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
