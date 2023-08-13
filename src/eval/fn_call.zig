const std = @import("std");

const mem = std.mem;

const desug = @import("../desug.zig");
const eval_ = @import("../eval.zig");

const InvalidInputError = eval_.InvalidInputError;
const Error = eval_.Error;
const Result = eval_.Result;

const Scope = eval_.Scope;

const expr = @import("expr.zig");

const AstFile = desug.expr.File;
const AstFnCall = desug.expr.FnCall;

const Expr = @import("../expr.zig").Expr;

pub fn eval(
    allocator: mem.Allocator,
    file: AstFile,
    scope: Scope,
    fn_call: AstFnCall,
) Result(Expr) {
    const func = switch (expr.eval(
        allocator,
        file,
        scope,
        fn_call.func.*,
    )) {
        .ok => |x| switch (x) {
            .@"fn" => |y| y,
            else => return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected FnDecl",
            )) },
        },
        .err => |e| return .{ .err = e },
    };

    var new_scope = scope.clone() catch @panic("Clone failed");
    defer new_scope.deinit();

    const arg_expr = switch (expr.eval(
        allocator,
        file,
        scope,
        fn_call.expr.*,
    )) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    new_scope.put(func.arg.value, arg_expr) catch {
        @panic("Allocation failed");
    };

    switch (expr.eval(
        allocator,
        file,
        new_scope,
        func.expr,
    )) {
        .ok => |x| return .{ .ok = x },
        .err => |e| return .{ .err = e },
    }
}
