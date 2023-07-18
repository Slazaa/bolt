const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");

const FormatError = lexer.FormatError;

const ParserResult = @import("../parser.zig").Result;

const Self = @This();

const keywords = [_][]const u8{
    "let",
};

keyword: []const u8,

pub fn lex(input: []const u8) ParserResult([]const u8, Self) {
    for (keywords) |keyword| {
        if (input.len < keyword.len or !mem.eql(u8, keyword, input[0..keyword.len])) {
            continue;
        }

        return .{ .ok = .{ input[keyword.len..], Self{
            .keyword = keyword,
        } } };
    }

    return .{ .err = .invalid_input };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Keyword | {s}\n", .{self.keyword}) catch return error.CouldNotFormat;
}
