const ast = @import("../ast.zig");

const AstExpr = ast.expr.Expr;

pub const Bind = @import("expr/Bind.zig");
pub const File = @import("expr/File.zig");

pub const Expr = union(enum) {
    const Self = @This();

    bind: Bind,
    file: File,

    pub fn desug(expr: AstExpr) Self {
        return switch (expr) {
            .bind => |x| Bind.desug(x),
            .file => |x| File.desug(x),
            else => @compileError("Not supported yet"),
        };
    }
};
