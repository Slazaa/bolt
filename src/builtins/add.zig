const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval = @import("../eval.zig");
const expr = @import("../expr.zig");

const AstExpr = ast.expr.Expr;

const Bind = ast.expr.Bind;
const FnDecl = ast.expr.FnDecl;
const Ident = ast.expr.Ident;
const Native = ast.expr.Native;

const Expr = expr.Expr;
const Num = expr.Num;

const Result = eval.Result;

const Scope = eval.Scope;

const ident = @import("../eval/ident.zig");

pub fn func(
    allocator: mem.Allocator,
    scope: Scope,
) !Result(Expr) {
    const x = try ident.eval(allocator, scope, Ident{
        .value = .{ .raw = "x" },
    });
    _ = x;

    const y = try ident.eval(allocator, scope, Ident{
        .value = .{ .raw = "y" },
    });
    _ = y;

    @panic("Not implemented yet");
}

pub fn decl(allocator: mem.Allocator) !Bind {
    var expr1 = try allocator.create(AstExpr);
    errdefer allocator.destroy(expr1);

    expr1.* = AstExpr.from(Native{ .func = func });

    errdefer expr1.deinit();

    var expr2 = try allocator.create(AstExpr);
    errdefer allocator.destroy(expr2);

    expr2.* = AstExpr.from(FnDecl{
        .allocator = allocator,
        .arg = .{ .raw = "y" },
        .expr = expr1,
    });

    var expr3 = try allocator.create(AstExpr);
    errdefer allocator.destroy(expr3);

    expr3.* = AstExpr.from(FnDecl{
        .allocator = allocator,
        .arg = .{ .raw = "x" },
        .expr = expr2,
    });

    return Bind{
        .allocator = allocator,
        .ident = .{ .raw = "+" },
        .expr = expr3,
    };
}
