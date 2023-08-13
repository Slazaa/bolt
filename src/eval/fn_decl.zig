const eval_ = @import("../eval.zig");

const desug = @import("../desug.zig");

const AstFnDecl = desug.expr.FnDecl;

const Fn = @import("../expr.zig").Fn;

pub fn eval(fn_decl: AstFnDecl) Fn {
    return .{
        .arg = fn_decl.arg,
        .expr = fn_decl.expr.*,
    };
}
