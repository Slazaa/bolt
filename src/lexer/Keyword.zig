const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;

const Self = @This();

const keywords = [_][]const u8{
    "let",
};

value: []const u8,

pub fn lex(input: []const u8) ParserResult([]const u8, Self) {
    for (keywords) |keyword| {
        if (input.len < keyword.len or !mem.startsWith(u8, input, keyword)) {
            continue;
        }

        return .{ .ok = .{ input[keyword.len..], Self{ .value = input[0..keyword.len] } } };
    }

    return .{ .err = .invalid_input };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Keyword | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
