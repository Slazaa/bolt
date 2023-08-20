const std = @import("std");

const mem = std.mem;

const desug = @import("../desug.zig");
const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");

const Result = eval_.Result;

const Scope = eval_.Scope;

const AstBuiltin = desug.expr.Builtin;

const Expr = expr.Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    builtin: AstBuiltin,
) !Result(Expr) {
    _ = builtin;
    _ = scope;
    _ = allocator;
}
