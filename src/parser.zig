const std = @import("std");

const mem = std.mem;

pub const alt = @import("parser/alt.zig").alt;
pub const digit0 = @import("parser/digit.zig").digit0;
pub const digit1 = @import("parser/digit.zig").digit1;

pub const Error = enum {
    invalid_input,
};

pub fn Result(comptime T: type) type {
    return union(enum) {
        const Self = @This();

        ok: struct { []const u8, T },
        err: Error,
    };
}
