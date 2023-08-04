const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;

const Position = @import("../Position.zig");

const Self = @This();

pub const Kind = enum {
    num,
};

kind: Kind,
value: []const u8,

fn lexNum(input: *[]const u8, position: *Position) ?Self {
    var input_ = input.*;
    var position_ = position.*;

    if (input_.len == 0 or !ascii.isDigit(input_[0])) {
        return null;
    }

    input_ = input_[1..];

    while (input_.len != 0 and ascii.isDigit(input_[0])) {
        input_ = input_[1..];
    }

    if (input_.len != 0 and input_[0] == '.') {
        input_ = input_[1..];

        if (input_.len == 0 or !ascii.isDigit(input_[0])) {
            return null;
        }

        input_ = input_[1..];

        while (input_.len != 0 and ascii.isDigit(input_[0])) {
            input_ = input_[1..];
        }
    }

    const token_size = input.len - input_.len;

    position_.column += token_size;
    position_.index += token_size;

    const value = input.*[0..token_size];

    input.* = input_;
    position.* = position_;

    return .{
        .kind = .num,
        .value = value,
    };
}

pub fn lex(input: *[]const u8, position: *Position) ?Self {
    const lexers = .{
        lexNum,
    };

    return inline for (lexers) |lexer| {
        if (lexer(input, position)) |literal| {
            break literal;
        }
    } else null;
}

pub fn format(self: Self, writer: fs.File.Writer) void {
    writer.print("Literal | {s}\n", .{self.value}) catch {
        @panic("Could not format");
    };
}
