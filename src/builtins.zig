const std = @import("std");

const desug = @import("desug.zig");
const expr_ = @import("expr.zig");

const DesugExpr = desug.expr.Expr;

const Expr = expr_.Expr;

pub fn add(expr: DesugExpr) Expr {
    const num = switch (expr) {
        .num => |x| x,
        else => @panic("Expected Num"),
    };
    _ = num;
}

pub const builtins = .{
    .{ "+", add },
};
