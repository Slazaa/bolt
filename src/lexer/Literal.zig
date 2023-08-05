const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const Position = @import("../Position.zig");

const Self = @This();

pub const Kind = enum {
    num,

    pub fn toBytes(self: Kind) []const u8 {
        return switch (self) {
            .num => "Num",
        };
    }
};

kind: Kind,
value: []const u8,
start_pos: Position,
end_pos: Position,

fn lexDigit(input: *[]const u8, position: *Position) bool {
    var input_ = input.*;

    while (input_.len != 0 and ascii.isDigit(input_[0])) {
        input_ = input_[1..];
    }

    const digit_count = input.len - input_.len;

    input.* = input_;

    position.column += digit_count;
    position.index += digit_count;

    return digit_count != 0;
}

fn lexNum(input: *[]const u8, position: *Position) ?Self {
    var input_ = input.*;
    var position_ = position.*;

    const start_pos = position_;

    if (!lexDigit(&input_, &position_)) {
        return null;
    }

    if (input_.len != 0 and input_[0] == '.') {
        input_ = input_[1..];

        position_.column += 1;
        position_.index += 1;

        if (!lexDigit(&input_, &position_)) {
            return null;
        }
    }

    const token_size = input.len - input_.len;

    const value = input.*[0..token_size];
    const end_pos = .{
        .line = start_pos.line,
        .column = start_pos.column + token_size - 1,
        .index = start_pos.index + token_size - 1,
    };

    input.* = input_;
    position.* = position_;

    return .{
        .kind = .num,
        .value = value,
        .start_pos = start_pos,
        .end_pos = end_pos,
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

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
    depth: usize,
) fmt.Error!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    try fmt.addDepth(&depth_tabs, depth);

    try fmt.print(writer, "{s}Literal: {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    kind: {s}\n", .{
        depth_tabs.items,
        self.kind.toBytes(),
    });

    try fmt.print(writer, "{s}    value: \"{s}\"\n", .{
        depth_tabs.items,
        self.value,
    });

    try fmt.print(writer, "{s}    start_pos:\n", .{
        depth_tabs.items,
    });

    try self.start_pos.format(
        allocator,
        writer,
        depth + 2,
    );

    try fmt.print(writer, "{s}    end_pos:\n", .{
        depth_tabs.items,
    });

    try self.end_pos.format(
        allocator,
        writer,
        depth + 2,
    );

    try fmt.print(writer, "{s}}}\n", .{
        depth_tabs.items,
    });
}
