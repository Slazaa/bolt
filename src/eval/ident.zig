const std = @import("std");

const mem = std.mem;

const eval_ = @import("../eval.zig");

const ast = @import("../ast.zig");
const expr = ast.expr;

const Result = eval_.Result;

const File = expr.File;
const Ident = expr.Ident;

const eval_expr = @import("expr.zig");

pub fn eval(comptime T: type, file: File, ident: Ident) Result(T) {
    for (file.binds.items) |bind| {
        if (mem.eql(u8, bind.ident.value, ident.value.value)) {
            return eval_expr.eval(T, file, bind.expr.*);
        }
    }

    @panic("Unknown Ident");
}
