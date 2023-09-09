const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");

const Result = eval_.Result;

const Scope = eval_.Scope;

const AstNative = ast.expr.Native;

const Expr = expr.Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    native: AstNative,
) !Result(Expr) {
    return try native.func(allocator, scope);
}
