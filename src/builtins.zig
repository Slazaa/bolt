const std = @import("std");

const mem = std.mem;

const desug = @import("desug.zig");
const expr = @import("expr.zig");

const Builtin = desug.expr.Builtin;

const Expr = expr.Expr;

pub fn add(allocator: mem.Allocator) Builtin {
    return Builtin.init(allocator, "+");
}

pub const builtins = .{
    add,
};
