const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

const FormatError = expr.FormatError;

const Token = lexer.Token;

const ParserResult = parser.Result;

pub const NumLit = @import("literal/NumLit.zig");

pub const Literal = union(enum) {
    const Self = @This();

    num: NumLit,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            NumLit => .{ .num = item },
            else => @compileError("Expected Literal, found " ++ @typeName(T)),
        };
    }

    pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult(
        []const Token,
        Self,
    ) {
        var input_ = input;

        const parsers = .{
            NumLit.parse,
        };

        const res = b: inline for (parsers) |p| {
            switch (p(allocator, input_)) {
                .ok => |x| break :b .{ x[0], Self.from(x[1]) },
                .err => {},
            }
        } else {
            var message = std.ArrayList(u8).init(allocator);

            message.appendSlice("Coult not parse Literal") catch {
                return .{ .err = .{ .allocation_failed = void{} } };
            };

            return .{ .err = .{ .invalid_input = .{ .message = message } } };
        };

        input_ = res[0];
        const literal = res[1];

        return .{ .ok = .{ input_, literal } };
    }

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: fs.File.Writer,
        depth: usize,
    ) FormatError!void {
        switch (self) {
            .num => |x| try x.format(allocator, writer, depth),
        }
    }
};
