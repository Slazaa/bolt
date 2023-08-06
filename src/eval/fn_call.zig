const std = @import("std");

const mem = std.mem;

const eval_ = @import("../eval.zig");
const expr = @import("../expr.zig");

const Result = eval_.Result;

const File = expr.File;
const FnCall = expr.FnCall;

pub fn eval(comptime T: type, file: File, fn_call: FnCall) Result(T) {
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
