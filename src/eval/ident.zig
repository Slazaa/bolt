const std = @import("std");

const mem = std.mem;

const desug = @import("../desug.zig");
const eval_ = @import("../eval.zig");

const Result = eval_.Result;
const Error = eval_.Error;
const InvalidInputError = eval_.InvalidInputError;

const Scope = eval_.Scope;

const expr = @import("../expr.zig");

const AstIdent = desug.expr.Ident;

const eval_expr = @import("expr.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    ident: AstIdent,
) Result(Expr) {
    if (scope.get(ident.value.value)) |expr_| {
        switch (eval_expr.eval(
            allocator,
            scope,
            expr_,
        )) {
            .ok => |x| return .{ .ok = x },
            .err => |e| return .{ .err = e },
        }
    }

    var message = std.ArrayList(u8).init(allocator);

    message.appendSlice("Unknown Ident: '") catch @panic("Allocation failed");
    message.appendSlice(ident.value.value) catch @panic("Allocation failed");
    message.appendSlice("'") catch @panic("Allocation failed");

    return .{ .err = Error.from(InvalidInputError{
        .message = message,
    }) };
}
