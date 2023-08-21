const std = @import("std");

const mem = std.mem;

const desug = @import("../desug.zig");
const eval = @import("../eval.zig");
const expr = @import("../expr.zig");

const DesugExpr = desug.expr.Expr;

const Bind = desug.expr.Bind;
const FnDecl = desug.expr.FnDecl;
const Ident = desug.expr.Ident;
const Native = desug.expr.Native;

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
    var expr1 = try allocator.create(DesugExpr);
    errdefer allocator.destroy(expr1);

    expr1.* = DesugExpr.from(Native{ .func = func });

    errdefer expr1.deinit();

    var expr2 = try allocator.create(DesugExpr);
    errdefer allocator.destroy(expr2);

    expr2.* = DesugExpr.from(FnDecl{
        .allocator = allocator,
        .arg = .{ .raw = "y" },
        .expr = expr1,
    });

    var expr3 = try allocator.create(DesugExpr);
    errdefer allocator.destroy(expr3);

    expr3.* = DesugExpr.from(FnDecl{
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
