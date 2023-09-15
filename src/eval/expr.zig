const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");

const AstExpr = ast.expr.Expr;

const Result = eval_.Result;

const Scope = eval_.Scope;

const expr_ = @import("../expr.zig");

const fn_call = @import("fn_call.zig");
const fn_decl = @import("fn_decl.zig");
const ident = @import("ident.zig");
const literal = @import("literal.zig");
const nat_fn = @import("nat_fn.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    expr: AstExpr,
) anyerror!Result(Expr) {
    return switch (expr) {
        .fn_call => |x| try fn_call.eval(
            allocator,
            scope,
            x,
        ),
        .fn_decl => |x| .{ .ok = .{
            .@"fn" = fn_decl.eval(x),
        } },
        .ident => |x| try ident.eval(
            allocator,
            scope,
            x,
        ),
        .literal => |x| .{
            .ok = try literal.eval(allocator, x),
        },
        .nat_fn => |x| try nat_fn.eval(
            allocator,
            scope,
            x,
        ),
        inline else => |x| {
            @panic("Not supported Expr, found " ++ @typeName(@TypeOf(x)));
        },
    };
}
