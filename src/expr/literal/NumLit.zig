const std = @import("std");

const ascii = std.ascii;
const fs = std.fs;
const mem = std.mem;

const expr = @import("../../expr.zig");
const lexer = @import("../../lexer.zig");
const parser = @import("../../parser.zig");

const FormatError = expr.FormatError;

const Token = lexer.Token;
const Literal = lexer.Literal;

const ParserResult = parser.Result;

const Self = @This();

value: Literal,

pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult(
    []const Token,
    Self,
) {
    var input_ = input;

    if (input_.len == 0) {
        var message = std.ArrayList(u8).init(allocator);

        message.appendSlice("Expected NumLit") catch {
            return .{ .err = .{ .allocation_failed = void{} } };
        };

        return .{ .err = .{ .invalid_input = .{ .message = message } } };
    }

    const literal = b: {
        switch (input_[0]) {
            .literal => |x| {
                if (x.kind != .num) {
                    var message = std.ArrayList(u8).init(allocator);

                    message.appendSlice("Expected NumLit") catch {
                        return .{ .err = .{ .allocation_failed = void{} } };
                    };

                    return .{ .err = .{ .invalid_input = .{
                        .message = message,
                    } } };
                }

                break :b x;
            },
            else => {
                var message = std.ArrayList(u8).init(allocator);

                message.appendSlice("Expected NumLit") catch {
                    return .{ .err = .{ .allocation_failed = void{} } };
                };

                return .{ .err = .{ .invalid_input = .{
                    .message = message,
                } } };
            },
        }
    };

    return .{ .ok = .{ input[1..], Self{
        .value = literal,
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

    writer.print("{s}NumLit {{\n", .{depth_tabs.items}) catch {
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
