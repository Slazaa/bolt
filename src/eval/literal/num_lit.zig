const std = @import("std");

const fmt = std.fmt;

const ast = @import("../../ast.zig");
const expr = ast.expr;

const NumLit = expr.NumLit;

pub fn eval(num_lit: NumLit) f64 {
    return fmt.parseFloat(f64, num_lit.value.value) catch unreachable;
}
