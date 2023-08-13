const desug = @import("../desug.zig");

const Literal = desug.expr.Literal;

const num_lit = @import("literal/num_lit.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(literal: Literal) Expr {
    return switch (literal) {
        .num => |x| .{ .num = num_lit.eval(x) },
    };
}
