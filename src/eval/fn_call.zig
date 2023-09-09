const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");
const expr_eval = @import("expr.zig");

const InvalidInputError = eval_.InvalidInputError;
const Error = eval_.Error;
const Result = eval_.Result;

const Scope = eval_.Scope;

const AstFnCall = ast.expr.FnCall;

const Expr = expr.Expr;

pub fn eval(
    allocator: mem.Allocator,
    scope: Scope,
    fn_call: AstFnCall,
) !Result(Expr) {
    var func = switch (try expr_eval.eval(
        allocator,
        scope,
        fn_call.func.*,
    )) {
        .ok => |x| switch (x) {
            .@"fn" => |y| y,
            else => return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected FnDecl",
            )) },
        },
        .err => |e| return .{ .err = e },
    };

    func.replaceArg(fn_call.expr.*);

    switch (try expr_eval.eval(
        allocator,
        scope,
        func.expr,
    )) {
        .ok => |x| return .{ .ok = x },
        .err => |e| return .{ .err = e },
    }
}
