const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");
const expr_eval = @import("expr.zig");

const ErrorInfo = eval_.ErrorInfo;
const InvalidInputError = eval_.InvalidInputError;

const Scope = eval_.Scope;

const AstFnCall = ast.expr.FnCall;

const Expr = expr.Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    fn_call: AstFnCall,
    err_info: ?*ErrorInfo,
) !Expr {
    var func = switch (try expr_eval.eval(
        allocator,
        scope,
        fn_call.func.*,
        err_info,
    )) {
        .@"fn" => |x| x,
        else => {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected FnDecl",
                ));
            }

            return error.InvalidInput;
        },
    };

    func.replaceArg(fn_call.expr.*);

    return try expr_eval.eval(
        allocator,
        scope,
        func.expr,
        err_info,
    );
}
