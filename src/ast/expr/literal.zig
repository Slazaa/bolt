const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const Error = ast.Error;
const Result = ast.Result;
const InvalidInputError = ast.InvalidInputError;

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

    pub fn parse(allocator: mem.Allocator, input: *[]const Token) !Result(Self) {
        const parsers = .{
            NumLit.parse,
        };

        inline for (parsers) |parser| {
            switch (try parser(allocator, input)) {
                .ok => |x| return .{ .ok = Self.from(x) },
                .err => |e| e.deinit(),
            }
        }

        return .{ .err = Error.from(try InvalidInputError.init(
            allocator,
            "Could not parse Literal",
        )) };
    }

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: Writer,
        depth: usize,
    ) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(allocator, writer, depth),
        }
    }
};
