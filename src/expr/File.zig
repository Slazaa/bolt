const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = expr.FormatError;

const Token = lexer.Token;

const ParserResult = parser.Result;

const Bind = @import("../Bind.zig");

const Self = @This();

binds: std.ArrayList(Bind),

pub fn deinit(self: Self) void {
    for (self.binds.items) |bind| {
        bind.deinit();
    }

    self.binds.deinit();
}

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    var binds = std.ArrayList(Bind).init(allocator);

    while (input_.len != 0) {
        const res = switch (Bind.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        input_ = res[0];

        binds.append(res[1]) catch return .{ .err = .{ .allocation_failed = void{} } };
    }

    return .{ .ok = .{ &[_]Token{}, .{
        .binds = binds,
    } } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}File {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    binds: [\n", .{depth_tabs.items}) catch return error.CouldNotFormat;

    for (self.binds.items) |bind| {
        try bind.format(allocator, writer, depth + 2);
    }

    writer.print("{s}    ]\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
