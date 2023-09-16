const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");
const expr_ = @import("../expr.zig");

const AstExpr = ast.expr.Expr;

const ErrorInfo = eval_.ErrorInfo;
const Scope = eval_.Scope;

const Expr = expr_.Expr;

const fn_call = @import("fn_call.zig");
const fn_decl = @import("fn_decl.zig");
const ident = @import("ident.zig");
const literal = @import("literal.zig");
const nat_fn = @import("nat_fn.zig");

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    expr: AstExpr,
    err_info: ?*ErrorInfo,
) anyerror!Expr {
    return switch (expr) {
        .fn_call => |x| try fn_call.eval(
            allocator,
            scope,
            x,
            err_info,
        ),
        .fn_decl => |x| Expr.from(fn_decl.eval(x)),
        .ident => |x| try ident.eval(
            allocator,
            scope,
            x,
            err_info,
        ),
        .literal => |x| try literal.eval(allocator, x),
        // .nat_fn => |x| try nat_fn.eval(
        //     allocator,
        //     scope,
        //     x,
        // ),
        inline else => |x| {
            @panic("Not supported Expr, found " ++ @typeName(@TypeOf(x)));
        },
    };
}
