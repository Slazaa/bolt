const std = @import("std");

const fs = std.fs;

const Writer = fs.File.Writer;

pub fn addDepth(buffer: *std.ArrayList(u8), depth: usize) void {
    for (0..depth) |_| {
        buffer.appendSlice("    ") catch {
            @panic("Coult nod append depth");
        };
    }
}

pub fn print(writer: Writer, comptime format: []const u8, args: anytype) void {
    writer.print(format, args) catch {
        @panic("Coult not print");
    };
}
