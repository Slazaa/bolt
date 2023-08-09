const std = @import("std");

const mem = std.mem;

const eval_ = @import("../eval.zig");
const ast = @import("../ast.zig");

const InvalidInputError = eval_.InvalidInputError;
const Error = eval_.Error;
const Result = eval_.Result;

const expr = @import("expr.zig");

const File = ast.expr.File;
const FnCall = ast.expr.FnCall;

pub fn eval(
    comptime T: type,
    allocator: mem.Allocator,
    file: File,
    fn_call: FnCall,
) Result(T) {
    const func = switch (expr.eval(
        T,
        file,
        fn_call.func.*,
    )) {
        .fn_decl => |x| x,
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected FnDecl",
        )) },
    };

    const expr_ = expr.eval(T, file, fn_call.expr.*);
    _ = expr_;
    _ = func;
}
