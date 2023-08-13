const std = @import("std");

const mem = std.mem;

const desug = @import("../desug.zig");
const eval_ = @import("../eval.zig");

const Result = eval_.Result;

const Scope = eval_.Scope;

const AstFile = desug.expr.File;
const AstIdent = desug.expr.Ident;

const eval_expr = @import("expr.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(
    allocator: mem.Allocator,
    file: AstFile,
    scope: Scope,
    ident: AstIdent,
) Result(Expr) {
    for (file.binds.items) |bind| {
        if (mem.eql(u8, bind.ident.value, ident.value.value)) {
            return eval_expr.eval(
                allocator,
                file,
                scope,
                bind.expr.*,
            );
        }
    }

    if (scope.get(ident.value.value)) |expr| {
        return .{ .ok = expr };
    }

    @panic("Unknown Ident");
}
