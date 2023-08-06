const ast = @import("../ast.zig");

const Literal = ast.expr.Literal;

const num_lit = @import("literal/num_lit.zig");

pub fn eval(comptime T: type, literal: Literal) T {
    return switch (literal) {
        .num => |x| num_lit.eval(x),
    };
}
