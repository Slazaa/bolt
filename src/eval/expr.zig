const File = @import("../expr.zig").File;
const Expr = @import("../expr.zig").Expr;

const ident = @import("ident.zig");
const literal = @import("literal.zig");

pub fn eval(comptime T: type, file: File, expr: Expr) !T {
    return switch (expr) {
        .ident => |x| ident.eval(T, file, x),
        .literal => |x| literal.eval(T, x),
        else => @panic("Not supported Expr"),
    };
}
