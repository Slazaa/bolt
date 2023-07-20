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

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var self = Self.init(allocator);
    var input_ = input;

    while (input_.len != 0) {
        const res = switch (Expr.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        input_ = res[0];

        self.exprs.append(res[1]) catch {
            @panic("Could not append to File");
        };
    }

    return .{ .ok = .{ &[_]Token{}, self } };
}

pub fn format(self: Self, writer: fs.File.Writer, comptime depth: usize) FormatError!void {
    const depth_tabs = "    " ** depth;

    writer.print("{s}File {{\n", .{depth_tabs}) catch return error.CouldNotFormat;
    writer.print("{s}    exprs: [\n", .{depth_tabs}) catch return error.CouldNotFormat;

    for (self.exprs.items) |item| {
        try item.format(writer, depth + 2);
    }

    writer.print("{s}    ]\n", .{depth_tabs}) catch return error.CouldNotFormat;
    writer.print("{s}}}\n", .{depth_tabs}) catch return error.CouldNotFormat;
}
