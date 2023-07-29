const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;
const InputResult = parser.InputResult;

const Position = @import("../Position.zig");

const Self = @This();

const puctuations = [_][]const u8{
    "=", ";",
};

value: []const u8,

pub fn lex(input: []const u8, position: Position) ParserResult(InputResult([]const u8), Self) {
    var input_ = input;
    var position_ = position;

    for (puctuations) |punct| {
        if (mem.startsWith(u8, input_, punct)) {
            const value = input_[0..punct.len];

            input_ = input_[punct.len..];

            position_.column += punct.len;
            position_.index += punct.len;

            return .{ .ok = .{ .{ input_, position_ }, Self{ .value = value } } };
        }
    }

    return .{ .err = .{ .invalid_input = .{ .message = null } } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Punct   | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
