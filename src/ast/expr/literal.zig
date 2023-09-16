const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const lexer = @import("../../lexer.zig");

const ast = @import("../../ast.zig");

const ErrorInfo = ast.ErrorInfo;
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

    pub fn parse(
        allocator: mem.Allocator,
        input: *[]const Token,
        err_info: ?*ErrorInfo,
    ) !Self {
        const parsers = .{
            NumLit.parse,
        };

        inline for (parsers) |parser| {
            if (parser(allocator, input, null)) |lit| {
                return Self.from(lit);
            } else |_| {}
        }

        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInputError.init(
                allocator,
                "Could not parse Literal",
            ));
        }

        return error.InvalidInput;
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
