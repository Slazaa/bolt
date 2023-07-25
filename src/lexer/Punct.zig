const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;

const Self = @This();

const puctuations = [_][]const u8{
    "=", ";",
};

value: []const u8,

pub fn lex(input: []const u8) ParserResult([]const u8, Self) {
    for (puctuations) |punct| {
        if (mem.startsWith(u8, input, punct)) {
            return .{ .ok = .{ input[punct.len..], Self{ .value = input[0..punct.len] } } };
        }
    }

    return .{ .err = .invalid_input };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Punct   | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
