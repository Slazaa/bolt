const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const desug = @import("desug.zig");

const AstExpr = desug.expr.Expr;

pub const Fn = @import("expr/Fn.zig");
pub const Num = @import("expr/Num.zig");

pub const Expr = union(enum) {
    const Self = @This();

    @"fn": Fn,
    num: Num,

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: Writer,
    ) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(allocator, writer),
        }
    }
};
