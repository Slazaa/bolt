const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const Error = ast.Error;
const Result = ast.Result;
const InvalidInputError = ast.InvalidInputError;

const Token = lexer.Token;
const Ident = lexer.Ident;

const Self = @This();

value: Ident,

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    if (input.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident, found nothing",
        )) };
    }

    const value = switch (input.*[0]) {
        .ident => |x| x,
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected Ident",
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

    try fmt.print(writer, "{s}Ident {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    value: {s}\n", .{
        depth_tabs.items,
        self.value.value,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
