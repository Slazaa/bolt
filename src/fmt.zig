const std = @import("std");

const fs = std.fs;

const Writer = fs.File.Writer;

pub const Error = error{
    AllocationFailed,
    PrintingFailed,
};

pub fn addDepth(buffer: *std.ArrayList(u8), depth: usize) Error!void {
    for (0..depth) |_| {
        buffer.appendSlice("    ") catch {
            return Error.AllocationFailed;
        };
    }
}

pub fn print(
    writer: Writer,
    comptime format: []const u8,
    args: anytype,
) Error!void {
    writer.print(format, args) catch {
        return Error.PrintingFailed;
    };
}
