const std = @import("std");

const mem = std.mem;

const File = @import("../expr.zig").File;
const FnCall = @import("../expr.zig").FnCall;

pub fn eval(comptime T: type, file: File, fn_call: FnCall) !T {
    const bind = for (file.binds.items) |bind| {
        if (!mem.eql(u8, fn_call.ident.value, bind.ident.value)) {
            continue;
        }

        break bind;
    } else {
        return error.IdentNotFound;
    };
    _ = bind;
}
