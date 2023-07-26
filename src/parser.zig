const std = @import("std");

const mem = std.mem;

const InvalidInputError = struct {
    const Self = @This();

    message: std.ArrayList(u8),

    pub fn deinit(self: Self) void {
        self.message.deinit();
    }
};

pub const Error = union(enum) {
    const Self = @This();

    allocation,
    invalid_input: InvalidInputError,

    pub fn deinit(self: Self) void {
        switch (self) {
            .invalid_input => |x| x.deinit(),
            else => {},
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
