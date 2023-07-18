const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const ParserResult = @import("parser.zig").Result;
const Parser = @import("parser.zig").Parser;

const alt = @import("parser.zig").alt;
const into = @import("parser.zig").into;

const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub const File = @import("expr/File.zig");
pub const NumLit = @import("expr/NumLit.zig");

pub const FormatError = error{
    CouldNotFormat,
};

pub const Expr = union(enum) {
    const Self = @This();

    file: File,
    num_lit: NumLit,

    pub fn from(comptime T: type) Parser(T, Self) {
        return struct {
            pub fn f(input: T) Self {
                return switch (T) {
                    File => .{ .file = input },
                    NumLit => .{ .num_lit = input },
                    else => @compileError("Expected Expr, found" ++ @typeName(T)),
                };
            }
        }.f;
    }

    pub fn deinit(self: *Self) void {
        switch (self) {
            .file => |file| file.deinit(),
        }
    }

    pub fn parse(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
        _ = allocator;

        return alt(
            Self,
            &[_]*const fn (input: []const Token) ParserResult([]const Token, Self){
                into(NumLit, Self, NumLit.parse, Self.from(NumLit)),
            },
        )(input);
    }

    pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
        switch (self) {
            .file => |x| try x.format(allocator, writer, depth),
            .num_lit => |x| try x.format(allocator, writer, depth),
        }
    }
};
