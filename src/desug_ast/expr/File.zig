const std = @import("std");

const mem = std.mem;

const ast = @import("../../ast.zig");

const File = ast.expr.File;

const Bind = @import("Bind.zig");

const Self = @This();

binds: std.ArrayList(Bind),

pub fn deinit(self: Self) void {
    for (self.binds.items) |bind| {
        bind.deinit();
    }

    self.binds.deinit();
}

pub fn desug(allocator: mem.Allocator, file: File) Self {
    const binds = std.ArrayList(Bind).initCapacity(
        allocator,
        file.binds.len,
    ) catch @panic("Allocation failed");

    for (file.binds.items) |bind| {
        binds.append(Bind.desug(bind));
    }

    return .{
        .binds = binds,
    };
}
