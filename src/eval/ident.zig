const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");

const Result = eval_.Result;
const Error = eval_.Error;
const InvalidInputError = eval_.InvalidInputError;

const Scope = eval_.Scope;

const expr = @import("../expr.zig");

const AstIdent = ast.expr.Ident;

const eval_expr = @import("expr.zig");

const Expr = @import("../expr.zig").Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    ident: AstIdent,
) !Result(Expr) {
    if (scope.get(ident.value.value)) |scope_item| {
        return switch (try eval_expr.eval(
            allocator,
            scope,
            scope_item,
        )) {
            .ok => |x| .{ .ok = x },
            .err => |e| .{ .err = e },
        };
    }

    var message = std.ArrayList(u8).init(allocator);

    try message.appendSlice("Unknown Ident: '");
    try message.appendSlice(ident.value.value);
    try message.appendSlice("'");

    return .{ .err = Error.from(InvalidInputError{
        .message = message,
    }) };
}
