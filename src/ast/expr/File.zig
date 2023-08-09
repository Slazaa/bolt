const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const Result = ast.Result;

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

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
    var binds = std.ArrayList(Bind).init(allocator);

    while (input.len != 0) {
        const bind = switch (Bind.parse(allocator, input)) {
            .ok => |x| x,
            .err => |e| {
                for (binds.items) |bind| {
                    bind.deinit();
                }

                binds.deinit();

                return .{ .err = e };
            },
        };

        binds.append(bind) catch {
            bind.deinit();

            for (binds.items) |bind_| {
                bind_.deinit();
            }

            binds.deinit();

            @panic("Allocation failed");
        };
    }

    if (input.len != 0) {
        binds.deinit();
        return .{ .err = .input_left };
    }

    return .{ .ok = .{
        .binds = binds,
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
