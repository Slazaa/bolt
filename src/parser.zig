const std = @import("std");

const mem = std.mem;

pub const digit0 = @import("parser/digit.zig").digit0;
pub const digit1 = @import("parser/digit.zig").digit1;
pub const tag = @import("parser/tag.zig").tag;

pub const Error = enum {
    invalid_input,
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
