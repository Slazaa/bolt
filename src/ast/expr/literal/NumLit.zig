const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const fmt = @import("../../../fmt.zig");

const lexer = @import("../../../lexer.zig");

const ast = @import("../../../ast.zig");

const ErrorInfo = ast.ErrorInfo;
const InvalidInput = ast.InvalidInputError;

const Token = lexer.Token;
const Literal = lexer.Literal;

const Self = @This();

value: Literal,

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
    err_info: ?*ErrorInfo,
) !Self {
    if (input.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInput.init(
                allocator,
                "Expected NumLit, found nothing",
            ));
        }

        return error.InvalidInput;
    }

    var value: ?Literal = null;

    switch (input.*[0]) {
        .literal => |x| if (x.kind == .num) {
            value = x;
        },
        else => {},
    }

    if (value == null) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInput.init(
                allocator,
                "Expected NumLit",
            ));
        }

        return error.InvalidInput;
    }

    const value_ = value.?;

    input.* = input.*[1..];

    return .{ .value = value_ };
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
