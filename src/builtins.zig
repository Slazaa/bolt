const expr = @import("expr.zig");

const NatFn = expr.NatFn;

pub const add = @import("builtins/add.zig");

pub const builtins = .{
    .{ "+", NatFn{ .func = add.func } },
};
