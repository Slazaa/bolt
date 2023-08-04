const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const Position = @import("../Position.zig");

const Self = @This();

const keywords = [_][]const u8{};

value: []const u8,

pub fn lex(input: *[]const u8, position: *Position) ?Self {
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
        };
    } else null;
}

pub fn format(self: Self, writer: fs.File.Writer) void {
    writer.print("Keyword | {s}\n", .{self.value}) catch {
        @panic("Could not format");
    };
}
