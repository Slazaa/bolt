const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const Expr = expr.Expr;
const IdentExpr = expr.Ident;

const FormatError = expr.FormatError;

const Token = lexer.Token;
const Ident = lexer.Ident;

const ParserResult = parser.Result;

const Self = @This();

ident: Ident,
args: std.ArrayList(Expr),

pub fn deinit(self: Self) void {
    self.args.deinit();
}

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult(
    []const Token,
    Self,
) {
    var input_ = input;

    if (input_.len == 0) {
        var message = std.ArrayList(u8).init(allocator);

        message.appendSlice("Expected Ident, found nothing") catch {
            return .{ .err = .{ .allocation_failed = void{} } };
        };

        return .{ .err = .{ .invalid_input = .{ .message = message } } };
    }

    const ident = switch (input_[0]) {
        .ident => |x| x,
        else => {
            var message = std.ArrayList(u8).init(allocator);

            message.appendSlice("Expected Ident") catch {
                return .{ .err = .{ .allocation_failed = void{} } };
            };

            return .{ .err = .{ .invalid_input = .{ .message = message } } };
        },
    };

    input_ = input_[1..];

    const parsers = .{
        IdentExpr.parse,
        Expr.parse,
    };

    var args = std.ArrayList(Expr).init(allocator);

    while (true) {
        const res = inline for (parsers) |parser_| {
            switch (parser_(allocator, input_)) {
                .ok => |x| break .{ x[0], switch (@TypeOf(x[1])) {
                    Expr => x[1],
                    else => Expr.from(x[1]),
                } },
                .err => |e| e.deinit(),
            }
        } else {
            break;
        };

        input_ = res[0];

        args.append(res[1]) catch {
            args.deinit();
            return .{ .err = .allocation_failed };
        };
    }

    if (args.items.len == 0) {
        args.deinit();

        var message = std.ArrayList(u8).init(allocator);

        message.appendSlice("Expected args, found nothing") catch {
            return .{ .err = .allocation_failed };
        };

        return .{ .err = .{ .invalid_input = .{ .message = message } } };
    }

    return .{ .ok = .{ input_, Self{
        .ident = ident,
        .args = args,
    } } };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: fs.File.Writer,
    depth: usize,
) FormatError!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    for (0..depth) |_| {
        depth_tabs.appendSlice("    ") catch return error.CouldNotFormat;
    }

    writer.print("{s}FnCall {{\n", .{depth_tabs.items}) catch {
        return error.CouldNotFormat;
    };

    writer.print("{s}    ident: {s}\n", .{
        depth_tabs.items,
        self.ident.value,
    }) catch {
        return error.CouldNotFormat;
    };

    writer.print("{s}    args: [\n", .{depth_tabs.items}) catch {
        return error.CouldNotFormat;
    };

    for (self.args.items) |arg| {
        try arg.format(allocator, writer, depth + 2);
    }

    writer.print("{s}    ]\n", .{depth_tabs.items}) catch {
        return error.CouldNotFormat;
    };

    writer.print("{s}}}\n", .{depth_tabs.items}) catch {
        return error.CouldNotFormat;
    };
}
