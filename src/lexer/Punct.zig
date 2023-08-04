const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Position = @import("../Position.zig");

const Self = @This();

value: []const u8,

pub fn lex(input: *[]const u8, position: *Position) ?Self {
    const puncts = [_][]const u8{
        "=", ";",
    };

    return for (puncts) |punct| {
        const value = input.*[0..punct.len];

        if (!mem.eql(u8, value, punct)) {
            continue;
        }

        input.* = input.*[punct.len..];

        position.column += punct.len;
        position.index += punct.len;

        break .{
            .value = value,
        };
    } else null;
}

pub fn format(self: Self, writer: fs.File.Writer) void {
    writer.print("Punct   | {s}\n", .{self.value}) catch {
        @panic("Could not format");
    };
}
