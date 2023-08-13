const std = @import("std");

const mem = std.mem;

const desug = @import("../desug.zig");
const eval_ = @import("../eval.zig");

const AstExpr = desug.expr.Expr;
const AstFile = desug.expr.File;

const Result = eval_.Result;

const Scope = eval_.Scope;

const fn_call = @import("fn_call.zig");
const fn_decl = @import("fn_decl.zig");
const ident = @import("ident.zig");
const literal = @import("literal.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(
    allocator: mem.Allocator,
    file: AstFile,
    scope: Scope,
    expr: AstExpr,
) Result(Expr) {
    return switch (expr) {
        .fn_call => |x| fn_call.eval(
            allocator,
            file,
            scope,
            x,
        ),
        .fn_decl => |x| .{ .ok = .{ .@"fn" = fn_decl.eval(x) } },
        .ident => |x| ident.eval(
            allocator,
            file,
            scope,
            x,
        ),
        .literal => |x| .{ .ok = literal.eval(x) },
        inline else => |x| {
            @panic("Not supported Expr, found " ++ @typeName(@TypeOf(x)));
        },
    };
}
