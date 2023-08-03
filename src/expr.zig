const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const ParserResult = @import("parser.zig").Result;
const Parser = @import("parser.zig").Parser;

const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub const File = @import("expr/File.zig");
pub const Ident = @import("expr/Ident.zig");
pub const Literal = @import("expr/literal.zig").Literal;
pub const NumLit = @import("expr/literal.zig").NumLit;

pub const FormatError = error{
    CouldNotFormat,
};

pub const Expr = union(enum) {
    const Self = @This();

    file: File,
    ident: Ident,
    literal: Literal,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            File => .{ .file = item },
            Ident => .{ .ident = item },
            Literal => .{ .literal = item },
            else => @compileError("Expected Expr, found " ++ @typeName(T)),
        };
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .file => |x| x.deinit(),
            else => {},
        }
    }

    pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult(
        []const Token,
        Self,
    ) {
        var input_ = input;

        const parsers = .{
            Literal.parse,
            Ident.parse,
        };

        const res = b: inline for (parsers) |parser| {
            switch (parser(allocator, input_)) {
                .ok => |x| break :b .{ x[0], Self.from(x[1]) },
                .err => |e| e.deinit(),
            }
        } else {
            var message = std.ArrayList(u8).init(allocator);

            message.appendSlice("Could not parse Expr") catch {
                return .{ .err = .{ .allocation_failed = void{} } };
            };

            return .{ .err = .{ .invalid_input = .{ .message = message } } };
        };

        input_ = res[0];
        const expr = res[1];

        return .{ .ok = .{ input_, expr } };
    }

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: fs.File.Writer,
        depth: usize,
    ) FormatError!void {
        switch (self) {
            .file => |x| try x.format(
                allocator,
                writer,
                depth,
            ),
            .ident => |x| try x.format(
                allocator,
                writer,
                depth,
            ),
            .literal => |x| try x.format(
                allocator,
                writer,
                depth,
            ),
        }
    }
};
