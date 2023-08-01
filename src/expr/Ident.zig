const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const Token = lexer.Token;
const Ident = lexer.Ident;

const ParserResult = parser.Result;

const FormatError = expr.FormatError;

const Self = @This();

value: Ident,

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult(
    []const Token,
    Self,
) {
    var input_ = input;

    if (input_.len == 0) {
        var message = std.ArrayList(u8).init(allocator);

        message.appendSlice("No input found") catch {
            return .{ .err = .{ .allocation_failed = void{} } };
        };

        return .{ .err = .{ .invalid_input = .{ .message = message } } };
    }

    const value = switch (input_[0]) {
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

    return .{ .ok = .{ input_, Self{
        .value = value,
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

    writer.print("{s}Ident {{\n", .{depth_tabs.items}) catch {
        return error.CouldNotFormat;
    };

    writer.print("{s}    value: {s}\n", .{
        depth_tabs.items,
        self.value.value,
    }) catch {
        return error.CouldNotFormat;
    };

    writer.print("{s}}}\n", .{depth_tabs.items}) catch {
        return error.CouldNotFormat;
    };
}
