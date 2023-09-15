const std = @import("std");

const mem = std.mem;

const ast = @import("ast.zig");

const AstExpr = ast.expr.Expr;
const AstFnDecl = ast.expr.FnDecl;
const AstNatFn = ast.expr.NatFn;

pub fn decl(allocator: mem.Allocator, func: anytype) !AstFnDecl {
    const T = @TypeOf(func);

    switch (T) {
        Fn => |X| {
            var last_expr = try allocator.create(AstExpr);
            errdefer allocator.destroy(last_expr);

            expr.* = AstExpr.from(AstNatFn{ .func = func });
        },
        else => @compileError("Expected function, found" ++ @typeName(T)),
    }
}
