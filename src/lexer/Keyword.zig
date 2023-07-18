const std = @import("std");

const mem = std.mem;

const ParserResult = @import("../parser.zig").Result;

const Self = @This();

const keywords = [_][]const u8{
    "let",
};

keyword: []const u8,

pub fn lex(input: []const u8) ParserResult(Self) {
    for (keywords) |keyword| {
        if (!mem.eql(u8, keyword, input[0..keyword.len])) {
            return .{ .err = .invalid_input };
        }

        return .{ .ok = .{ input[keyword.len..], Self{
            .keyword = keyword,
        } } };
    }
}
