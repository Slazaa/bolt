const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");

const Scope = eval_.Scope;

const AstNatFn = ast.expr.NatFn;

const Expr = expr.Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    nat_fn: AstNatFn,
) Expr {
    _ = nat_fn;
    _ = scope;
    _ = allocator;
}
