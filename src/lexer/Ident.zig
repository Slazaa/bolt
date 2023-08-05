const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const Position = @import("../Position.zig");

const Self = @This();

value: []const u8,
start_pos: Position,
end_pos: Position,

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

    const start_pos = position_;

    if (!startsWithValidHeadChar(input_)) {
        return null;
    }

    input_ = input_[1..];

    while (startsWithValidTailChar(input_)) {
        input_ = input_[1..];
    }

    const token_size = input.len - input_.len;

    const value = input.*[0..token_size];

    const end_pos = .{
        .line = start_pos.line,
        .column = start_pos.column + token_size - 1,
        .index = start_pos.index + token_size - 1,
    };

    position_.column += token_size;
    position_.index += token_size;

    input.* = input_;
    position.* = position_;

    return .{
        .value = value,
        .start_pos = start_pos,
        .end_pos = end_pos,
    };
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

    try fmt.print(writer, "{s}Ident: {{\n", .{
        depth_tabs.items,
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
