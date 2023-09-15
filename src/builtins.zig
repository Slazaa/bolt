const expr = @import("expr.zig");

const NatFn = expr.NatFn;

pub fn add(x: f64, y: f64) f64 {
    _ = y;
    _ = x;
    @panic("TODO");
}

pub const builtins = .{
    .{ "+", add },
};
