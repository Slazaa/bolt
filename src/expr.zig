const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const Result = @import("parser.zig").Result;

const alt = @import("parser.zig").alt;
const into = @import("parser.zig").into;

pub const File = @import("expr/File.zig");
pub const NumLit = @import("expr/NumLit.zig");

pub const FormatError = error{
    CouldNotFormat,
};

pub const Expr = union(enum) {
    const Self = @This();

    file: File,
    num_lit: NumLit,

    pub fn from(expr: anytype) Self {
        const ExprT = @TypeOf(expr);

        return switch (ExprT) {
            File => .{ .file = expr },
            NumLit => .{ .num_lit = expr },
            else => @compileError("Expected Expr, found" ++ @typeName(ExprT)),
        };
    }

    pub fn deinit(self: *Self) void {
        switch (self) {
            .file => |file| file.deinit(),
        }
    }

    pub fn parse(allocator: mem.Allocator, input: []const u8) Result(Self) {
        _ = allocator;

        return alt(
            Self,
            &[_]*const fn (input: []const u8) Result(Self){
                into(NumLit, Self, NumLit.parse, Self.from),
            },
        )(input);
    }

    pub fn format(self: Self, allocator: mem.Allocator, writer: fs.File.Writer, depth: usize) FormatError!void {
        switch (self) {
            .file => |file| try file.format(allocator, writer, depth),
            .num_lit => |num_lit| try num_lit.format(allocator, writer, depth),
        }
    }
};
