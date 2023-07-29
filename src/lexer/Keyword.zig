const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;
const InputResult = parser.InputResult;

const Position = @import("../Position.zig");

const Self = @This();

const keywords = [_][]const u8{};

value: []const u8,

pub fn lex(input: []const u8, position: Position) ParserResult(InputResult([]const u8), Self) {
    var input_ = input;
    var position_ = position;

    for (keywords) |keyword| {
        if (mem.startsWith(u8, input, keyword) and (input.len == keyword.len or !ascii.isAlphanumeric(input[keyword.len]))) {
            input_ = input_[keyword.len..];

            position_.column += keyword.len;
            position_.index += keyword.len;

            return .{ .ok = .{ .{ input_, position_ }, Self{
                .value = input[0..keyword.len],
            } } };
        }
    }

    return .{ .err = .{ .invalid_input = .{ .message = null } } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Keyword | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
