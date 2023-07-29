const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = lexer.FormatError;

const ParserResult = parser.Result;
const InputResult = parser.InputResult;

const Position = @import("../Position.zig");

const Self = @This();

pub const Kind = enum {
    num,
};

value: []const u8,
kind: Kind,

fn lexNum(input: []const u8, position: Position) ParserResult(InputResult([]const u8), Self) {
    var input_ = input;
    var position_ = position;

    if (input_.len == 0 or !ascii.isDigit(input_[0])) {
        return .{ .err = .{ .invalid_input = .{ .message = null } } };
    }

    input_ = input_[1..];

    while (input_.len != 0 and ascii.isDigit(input_[0])) {
        input_ = input_[1..];
    }

    if (input_.len != 0 and input_[0] == '.') {
        input_ = input_[1..];

        if (input_.len != 0 and ascii.isDigit(input_[0])) {
            input_ = input_[1..];

            while (input_.len != 0 and ascii.isDigit(input_[0])) {
                input_ = input_[1..];
            }
        }
    }

    const token_size = input.len - input_.len;

    position_.column += token_size;
    position_.index += token_size;

    return .{ .ok = .{ .{ input_, position_ }, Self{
        .value = input[0..token_size],
        .kind = .num,
    } } };
}

pub fn lex(input: []const u8, position: Position) ParserResult(struct { []const u8, Position }, Self) {
    const lexers = .{
        lexNum,
    };

    inline for (lexers) |l| {
        switch (l(input, position)) {
            .ok => |x| return .{ .ok = x },
            .err => {},
        }
    }

    return .{ .err = .{ .invalid_input = .{ .message = null } } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    writer.print("Literal | {s}\n", .{self.value}) catch return error.CouldNotFormat;
}
