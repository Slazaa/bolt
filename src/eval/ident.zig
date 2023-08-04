const std = @import("std");

const mem = std.mem;

const File = @import("../expr.zig").File;
const Ident = @import("../expr.zig").Ident;

const expr = @import("expr.zig");

pub fn eval(comptime T: type, file: File, ident: Ident) !T {
    for (file.binds.items) |bind| {
        if (mem.eql(u8, bind.ident.value, ident.value.value)) {
            return expr.eval(T, file, bind.expr.*);
        }
    }

    return error.UnknownIdent;
}
