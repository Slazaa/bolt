const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const ErrorInfo = ast.ErrorInfo;
const InvalidInputError = ast.InvalidInputError;

const Token = lexer.Token;
const Ident = lexer.Ident;

const Self = @This();

value: Ident,

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
    err_info: ?*ErrorInfo,
) !Self {
    if (input.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(InvalidInputError.init(
                allocator,
                "Expected Ident, found nothing",
            ));
        }

        return error.InvalidInput;
    }

    const value = switch (input.*[0]) {
        .ident => |x| x,
        else => {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected Ident",
                ));
            }

            return error.InvalidInput;
        },
    };

    input.* = input.*[1..];

    return .{ .value = value };
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
