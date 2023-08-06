const eval_ = @import("../eval.zig");
const ast = @import("../ast.zig");

const File = ast.expr.File;
const Expr = ast.expr.Expr;

const Result = eval_.Result;

const ident = @import("ident.zig");
const literal = @import("literal.zig");

pub fn eval(comptime T: type, file: File, expr: Expr) Result(T) {
    return switch (expr) {
        .ident => |x| ident.eval(T, file, x),
        .literal => |x| .{ .ok = literal.eval(T, x) },
        else => @panic("Not supported Expr"),
    };
}
