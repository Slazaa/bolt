const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval = @import("../eval.zig");
const expr = @import("../expr.zig");

const AstExpr = ast.expr.Expr;

const Bind = ast.expr.Bind;
const FnDecl = ast.expr.FnDecl;
const Ident = ast.expr.Ident;

const Expr = expr.Expr;
const NatFn = expr.NatFn;
const Num = expr.Num;

const Result = eval.Result;

const Scope = eval.Scope;

const ident = @import("../eval/ident.zig");

pub fn func(scope: Scope) !Result(Expr) {
    const x = scope.get("x") orelse @panic("Expected argument");
    _ = x;
    const y = scope.get("y") orelse @panic("Expected argument");
    _ = y;

    @panic("Not implemented yet");
}
