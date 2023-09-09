const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const ast = @import("ast.zig");

const fmt = @import("fmt.zig");

const AstExpr = ast.expr.Expr;

pub const Fn = @import("expr/Fn.zig");
pub const Num = @import("expr/Num.zig");

pub const Expr = union(enum) {
    const Self = @This();

    @"fn": Fn,
    num: Num,

    pub fn deinit(self: Self) void {
        switch (self) {
            .num => |x| x.deinit(),
            else => {},
        }
    }

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: Writer,
        depth: usize,
    ) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(allocator, writer, depth),
        }
    }
};
