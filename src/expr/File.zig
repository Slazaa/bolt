const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const expr = @import("../expr.zig");
const parser = @import("../parser.zig");

const Result = parser.Result;

const Expr = @import("../expr.zig").Expr;

const Self = @This();

exprs: std.ArrayList(Expr),

pub fn init(allocator: mem.Allocator) Self {
    return Self{
        .exprs = std.ArrayList(Expr).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.exprs.deinit();
}

pub fn parse(allocator: mem.Allocator, input: []const u8) Result(Self) {
    var self = Self.init(allocator);
    var new_input = input;

    while (new_input.len != 0) {
        const res = switch (Expr.parse(allocator, new_input)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        new_input = res[0];

        self.exprs.append(res[1]) catch {
            @panic("Could not append to File");
        };
    }

    return .{ .ok = .{ &[_]u8{}, self } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) expr.FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}File {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    exprs: [\n", .{depth_tabs.items}) catch return error.CouldNotFormat;

    for (self.exprs.items) |item| {
        try item.format(allocator, writer, depth + 2);
    }

    writer.print("{s}    ]\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
