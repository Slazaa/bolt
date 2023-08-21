const eval_ = @import("../eval.zig");

const desug = @import("../desug.zig");

const AstFnDecl = desug.expr.FnDecl;

const expr = @import("../expr.zig");

const Fn = expr.Fn;

pub fn eval(fn_decl: AstFnDecl) Fn {
    return .{
        .arg = fn_decl.arg.value(),
        .expr = fn_decl.expr.*,
    };
}
