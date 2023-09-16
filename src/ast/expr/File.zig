const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const ErrorInfo = ast.ErrorInfo;

const Token = lexer.Token;

const Bind = @import("Bind.zig");

const Self = @This();

binds: std.ArrayList(Bind),

pub fn deinit(self: Self) void {
    for (self.binds.items) |bind| {
        bind.deinit();
    }

    self.binds.deinit();
}

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
    err_info: ?*ErrorInfo,
) !Self {
    var binds = std.ArrayList(Bind).init(allocator);

    errdefer {
        for (binds.items) |bind| {
            bind.deinit();
        }

        binds.deinit();
    }

    while (input.len != 0) {
        const bind = try Bind.parse(
            allocator,
            input,
            err_info,
        );

        errdefer bind.deinit();

        try binds.append(bind);
    }

    if (input.len != 0) {
        return error.InputLeft;
    }

    return .{ .binds = binds };
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

    try fmt.print(writer, "{s}File {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    binds: [\n", .{
        depth_tabs.items,
    });

    for (self.binds.items) |bind| {
        try bind.format(allocator, writer, depth + 2);
    }

    try fmt.print(writer, "{s}    ]\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
