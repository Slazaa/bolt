const std = @import("std");

const mem = std.mem;

const eval_ = @import("../eval.zig");
const ast = @import("../ast.zig");

const File = ast.expr.File;
const Expr = ast.expr.Expr;

const Result = eval_.Result;

const fn_call = @import("fn_call.zig");
const ident = @import("ident.zig");
const literal = @import("literal.zig");

pub fn eval(
    comptime T: type,
    allocator: mem.Allocator,
    file: File,
    expr: Expr,
) Result(T) {
    return switch (expr) {
        .fn_call => |x| fn_call.eval(
            T,
            allocator,
            file,
            x,
        ),
        .ident => |x| ident.eval(T, file, x),
        .literal => |x| .{ .ok = literal.eval(T, x) },
        else => @panic("Not supported Expr"),
    };
}
