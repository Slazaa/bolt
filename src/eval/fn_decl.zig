const eval_ = @import("../eval.zig");

const ast = @import("../ast.zig");
const expr = @import("../expr.zig");

const AstFnDecl = ast.expr.FnDecl;

const Fn = expr.Fn;

pub fn eval(fn_decl: AstFnDecl) Fn {
    return .{
        .arg = fn_decl.arg.value(),
        .expr = fn_decl.expr.*,
    };
}
