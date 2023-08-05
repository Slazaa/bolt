const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const Position = @import("../Position.zig");

const Self = @This();

value: []const u8,
start_pos: Position,
end_pos: Position,

pub fn lex(input: *[]const u8, position: *Position) ?Self {
    const puncts = [_][]const u8{
        "=", ";",
    };

    const start_pos = position.*;

    return for (puncts) |punct| {
        const value = input.*[0..punct.len];

        if (!mem.eql(u8, value, punct)) {
            continue;
        }

        const end_pos = .{
            .line = start_pos.line,
            .column = start_pos.column + punct.len - 1,
            .index = start_pos.index + punct.len - 1,
        };

        input.* = input.*[punct.len..];

        position.column += punct.len;
        position.index += punct.len;

        break .{
            .value = value,
            .start_pos = start_pos,
            .end_pos = end_pos,
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

    try fmt.print(writer, "{s}Punct: {{\n", .{
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

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
