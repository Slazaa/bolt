const std = @import("std");

const fmt = std.fmt;

const desug = @import("../../desug.zig");
const expr = @import("../../expr.zig");

const AstNumLit = desug.expr.NumLit;

const Num = expr.Num;

pub fn eval(num_lit: AstNumLit) Num {
    return .{
        .value = num_lit.value.value,
    };
}
