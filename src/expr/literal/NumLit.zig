const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const fmt = @import("../../fmt.zig");

const expr = @import("../../expr.zig");
const lexer = @import("../../lexer.zig");

const Error = expr.Error;
const Result = expr.Result;
const InvalidInput = expr.InvalidInputError;

const Token = lexer.Token;
const Literal = lexer.Literal;

const Self = @This();

value: Literal,

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    if (input.len == 0) {
        return .{ .err = Error.from(InvalidInput.init(
            allocator,
            "Expected NumLit, found nothing",
        )) };
    }

    const value = switch (input.*[0]) {
        .literal => |x| if (x.kind != .num) {
            return .{ .err = Error.from(InvalidInput.init(
                allocator,
                "Expected NumLit",
            )) };
        } else x,
        else => return .{ .err = Error.from(InvalidInput.init(
            allocator,
            "Expected NumLit",
        )) },
    };

    input.* = input.*[1..];

    return .{ .ok = .{
        .value = value,
    } };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: fs.File.Writer,
    depth: usize,
) fmt.Error!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    try fmt.addDepth(&depth_tabs, depth);

    try fmt.print(writer, "{s}NumLit {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    value: {s}\n", .{
        depth_tabs.items,
        self.value.value,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
