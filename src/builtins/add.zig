const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval = @import("../eval.zig");
const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");

const AstExpr = ast.expr.Expr;

const AstFnDecl = ast.expr.FnDecl;
const AstIdent = ast.expr.Ident;
const AstNatFn = ast.expr.NatFn;

const Expr = expr.Expr;
const NatFn = expr.NatFn;
const Num = expr.Num;

const Result = eval.Result;

const Scope = eval.Scope;

const IdentTok = lexer.Ident;

const Position = @import("../Position.zig");

const ident = @import("../eval/ident.zig");

fn func(scope: Scope) !Result(Expr) {
    const x = scope.get("x") orelse @panic("Expected argument");
    _ = x;
    const y = scope.get("y") orelse @panic("Expected argument");
    _ = y;

    @panic("Not implemented yet");
}

pub fn decl(allocator: mem.Allocator) !AstFnDecl {
    var expr1 = try allocator.create(AstExpr);
    errdefer allocator.destroy(expr1);

    expr1.* = AstExpr.from(AstNatFn{ .func = func });

    errdefer expr1.deinit();

    var expr2 = try allocator.create(AstExpr);
    errdefer allocator.destroy(expr2);

    expr2.* = AstExpr.from(AstFnDecl{
        .allocator = allocator,
        .arg = .{
            .value = "x",
            .start_pos = Position.default(),
            .end_pos = Position.default(),
        },
        .expr = expr1,
    });

    errdefer expr2.deinit();

    return .{
        .allocator = allocator,
        .arg = .{
            .value = "y",
            .start_pos = Position.default(),
            .end_pos = Position.default(),
        },
        .expr = expr2,
    };
}
