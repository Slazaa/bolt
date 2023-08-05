const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const fmt = @import("../fmt.zig");

const expr = @import("../expr.zig");
const lexer = @import("../lexer.zig");

const Error = expr.Error;
const Result = expr.Result;
const InvalidInputError = expr.InvalidInputError;

const Token = lexer.Token;

const NumLit = @import("literal/NumLit.zig");

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

    pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Self) {
        const parsers = .{
            NumLit.parse,
        };

        const literal = inline for (parsers) |parser| {
            switch (parser(allocator, input)) {
                .ok => |x| break Self.from(x),
                .err => |e| e.deinit(),
            }
        } else {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Could not parse Literal",
            )) };
        };

        return .{ .ok = literal };
    }

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: fs.File.Writer,
        depth: usize,
    ) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(allocator, writer, depth),
        }
    }
};
