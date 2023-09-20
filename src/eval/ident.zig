const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");

const ErrorInfo = eval_.ErrorInfo;
const InvalidInputError = eval_.InvalidInputError;
const Scope = eval_.Scope;

const Expr = expr.Expr;

const AstIdent = ast.expr.Ident;

const eval_expr = @import("expr.zig");

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    ident: AstIdent,
    err_info: ?*ErrorInfo,
) !Expr {
    if (scope.get(ident.value.value)) |scope_item| {
        return try eval_expr.eval(
            allocator,
            scope,
            scope_item,
            err_info,
        );
    }

    var message = std.ArrayList(u8).init(allocator);
    defer message.deinit();

    try message.appendSlice("Unknown Ident '");
    try message.appendSlice(ident.value.value);
    try message.appendSlice("'");

    if (err_info) |info| {
        info.* = ErrorInfo.from(try InvalidInputError.init(
            allocator,
            message.items,
        ));
    }

    return error.InvalidInput;
}
