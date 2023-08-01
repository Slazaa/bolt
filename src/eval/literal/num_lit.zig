const std = @import("std");

const fmt = std.fmt;

const NumLit = @import("../../expr.zig").NumLit;

pub fn eval(num_lit: NumLit) f64 {
    return fmt.parseFloat(f64, num_lit.value.value) catch unreachable;
}
