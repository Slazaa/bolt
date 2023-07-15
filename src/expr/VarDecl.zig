const std = @import("std");

const mem = std.mem;

const parser = @import("../parser.zig");

const Result = parser.Result;

const Self = @This();

ident: []const u8,
mutable: bool,
value: ?[]const u8,

pub fn parse(allocator: mem.Allocator, input: []const u8) Result(Self) {
    _ = input;
    _ = allocator;
}
