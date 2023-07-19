const std = @import("std");

const mem = std.mem;

const expr = @import("../expr.zig");
const parser = @import("../parser.zig");

const Expr = expr.Expr;

const Self = @This();

ident: []const u8,
mutable: bool,
expr: ?Expr,

pub fn parse(allocator: mem.Allocator, input: []const u8) parser.Result(Self) {
    _ = input;
    _ = allocator;
}
