const std = @import("std");

const mem = std.mem;

const lexer = @import("../lexer.zig");
const parser = @import("../parser.zig");

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

    pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
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
            return .{ .err = .invalid_input };
        };

        input_ = res[0];
        const literal = res[1];

        return .{ .ok = .{ input_, literal } };
    }
};
