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

fn deinitBinds(binds: std.ArrayList(Bind)) void {
    for (binds.items) |bind| {
        bind.deinit();
    }

    binds.deinit();
}

pub fn deinit(self: Self) void {
    deinitBinds(self.binds);
}

pub fn parse(allocator: mem.Allocator, input: *[]const Token) !Result(Self) {
    var binds = std.ArrayList(Bind).init(allocator);
    errdefer deinitBinds(binds);

    while (input.len != 0) {
        const bind = switch (try Bind.parse(
            allocator,
            input,
        )) {
            .ok => |x| x,
            .err => |e| {
                deinitBinds(binds);
                return .{ .err = e };
            },
        };

        errdefer bind.deinit();

        try binds.append(bind);
    }

    if (input.len != 0) {
        deinitBinds(binds);
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
