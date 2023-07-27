const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("lexer.zig");

const FormatError = lexer.FormatError;

const InvalidInputError = struct {
    const Self = @This();

    message: ?std.ArrayList(u8),

    pub fn deinit(self: Self) void {
        if (self.message) |message| {
            message.deinit();
        }
    }

    pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
        if (self.message) |message| {
            writer.print("Invalid input: {s}\n", .{message.items}) catch return error.CouldNotFormat;
        } else {
            writer.writeAll("Invalid input") catch return error.CouldNotFormat;
        }
    }
};

pub const Error = union(enum) {
    const Self = @This();

    allocation_failed,
    invalid_input: InvalidInputError,

    pub fn deinit(self: Self) void {
        switch (self) {
            .invalid_input => |x| x.deinit(),
            else => {},
        }
    }

    pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
        switch (self) {
            .allocation_failed => writer.writeAll("Allocation failed") catch return error.CouldNotFormat,
            .invalid_input => |x| try x.format(writer),
        }
    }
};

pub fn Result(comptime I: type, comptime O: type) type {
    return union(enum) {
        const Self = @This();

        ok: struct { I, O },
        err: Error,
    };
}

pub fn Parser(comptime I: type, comptime O: type) type {
    return *const fn (I) Result(I, O);
}
