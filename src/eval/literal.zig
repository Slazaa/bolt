const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");

const Literal = ast.expr.Literal;

const num_lit = @import("literal/num_lit.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(allocator: mem.Allocator, literal: Literal) !Expr {
    return switch (literal) {
        .num => |x| .{
            .num = try num_lit.eval(allocator, x),
        },
    };
}
