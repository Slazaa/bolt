const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = @import("../expr.zig").FormatError;

const Expr = @import("../expr.zig").Expr;
const Ident = @import("../expr.zig").Ident;

const Token = lexer.Token;

const ParserResult = parser.Result;

const Self = @This();

allocator: mem.Allocator,
ident: Ident,
params: std.ArrayList(Expr),
expr: ?*Expr,

pub fn deinit(self: Self) void {
    self.params.deinit();

    if (self.expr) |e| {
        e.deinit();
        self.allocator.destroy(e);
    }
}

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    if (input_.len == 0) {
        return .{ .err = .invalid_input };
    }

    switch (input_[0]) {
        .keyword => |x| if (!mem.eql(u8, x.value, "let")) return .{ .err = .invalid_input },
        else => {},
    }

    input_ = input_[1..];

    const ident = b: {
        const res = switch (Ident.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        input_ = res[0];

        break :b res[1];
    };

    var params = std.ArrayList(Expr).init(allocator);

    while (true) {
        const res = switch (Expr.parse(allocator, input_)) {
            .ok => |x| x,
            .err => break,
        };

        input_ = res[0];
        params.append(res[1]) catch {
            params.deinit();
            return .{ .err = .invalid_input };
        };
    }

    if (input_.len == 0) {
        params.deinit();
        return .{ .err = .invalid_input };
    }

    switch (input_[0]) {
        .punct => |x| {
            if (!mem.eql(u8, x.value, "=")) {
                params.deinit();
                return .{ .err = .invalid_input };
            }

            input_ = input_[1..];
        },
        else => {
            params.deinit();
            return .{ .err = .invalid_input };
        },
    }

    const expr = b: {
        const res = switch (Expr.parse(allocator, input_)) {
            .ok => |x| x,
            .err => |e| {
                params.deinit();
                return .{ .err = e };
            },
        };

        input_ = res[0];

        const expr = allocator.create(Expr) catch {
            params.deinit();
            return .{ .err = .invalid_input };
        };

        expr.* = res[1];

        break :b expr;
    };

    return .{ .ok = .{ input_, Self{
        .allocator = allocator,
        .ident = ident,
        .params = params,
        .expr = expr,
    } } };
}

pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}FnDecl {{\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    writer.print("{s}    ident:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    try self.ident.format(allocator, writer, depth + 2);
    writer.print("{s}    params: [\n", .{depth_tabs.items}) catch return error.CouldNotFormat;

    for (self.params.items) |param| {
        try param.format(allocator, writer, depth + 2);
    }

    writer.print("{s}    ]\n", .{depth_tabs.items}) catch return error.CouldNotFormat;

    if (self.expr) |e| {
        writer.print("{s}    expr:\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
        try e.format(allocator, writer, depth + 2);
    } else {
        writer.print("{s}    expr: null\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
    }

    writer.print("{s}}}\n", .{depth_tabs.items}) catch return error.CouldNotFormat;
}
