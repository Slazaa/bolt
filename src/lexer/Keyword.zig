const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const Position = @import("../Position.zig");

const Self = @This();

const keywords = [_][]const u8{};

value: []const u8,
start_pos: Position,
end_pos: Position,

pub fn lex(input: *[]const u8, position: *Position) ?Self {
    const start_pos = position.*;

    return for (keywords) |keyword| {
        const value = input[0..keyword.len];

        if (!mem.eql(u8, value, keyword)) {
            continue;
        }

        input.* = input[keyword.len..];

        position.column += keyword.len;
        position.index += keyword.len;

        break .{
            .value = value,
            .start_pos = start_pos,
            .end_pos = position.*,
        };
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

    try fmt.print(writer, "{s}Keyword: {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    value: {s}\n", .{
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

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
