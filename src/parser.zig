const std = @import("std");

const mem = std.mem;

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
