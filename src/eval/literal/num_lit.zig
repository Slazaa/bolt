const std = @import("std");

const fmt = std.fmt;
const mem = std.mem;

const desug = @import("../../desug.zig");
const expr = @import("../../expr.zig");

const AstNumLit = desug.expr.NumLit;

const Num = expr.Num;

pub fn eval(allocator: mem.Allocator, num_lit: AstNumLit) !Num {
    var value = std.ArrayList(u8).init(allocator);
    errdefer value.deinit();

    try value.appendSlice(num_lit.value.value);

    return .{
        .allocator = allocator,
        .value = value,
    };
}
