const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;

const Position = @import("../Position.zig");

const Self = @This();

value: []const u8,

pub fn startsWithValidHeadChar(input: []const u8) bool {
    return input.len != 0 and (ascii.isAlphabetic(input[0]) or input[0] == '_');
}

pub fn startsWithValidTailChar(input: []const u8) bool {
    return input.len != 0 and
        (ascii.isAlphanumeric(input[0]) or input[0] == '_');
}

pub fn lex(input: *[]const u8, position: *Position) ?Self {
    var input_ = input.*;
    var position_ = position.*;

    if (!startsWithValidHeadChar(input_)) {
        return null;
    }

    input_ = input_[1..];

    while (startsWithValidTailChar(input_)) {
        input_ = input_[1..];
    }

    const token_size = input.len - input_.len;

    position_.column += token_size;
    position_.index += token_size;

    const value = input.*[0..token_size];

    input.* = input_;
    position.* = position_;

    return .{
        .value = value,
    };
}

pub fn format(self: Self, writer: fs.File.Writer) void {
    writer.print("Ident   | {s}\n", .{self.value}) catch {
        @panic("Could not format");
    };
}
