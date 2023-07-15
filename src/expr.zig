const std = @import("std");

const mem = std.mem;

const Result = @import("parser.zig").Result;

const alt = @import("parser.zig").alt;

pub const File = @import("expr/File.zig");
pub const NumLit = @import("expr/NumLit.zig");

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
            .File => |file| file.deinit(),
        }
    }

    fn toExpr(comptime T: type, parser: *const fn (input: []const u8) Result(T)) *const fn (input: []const u8) Result(Self) {
        return struct {
            pub fn f(input: []const u8) Result(Self) {
                const res = switch (parser(input)) {
                    .ok => |x| x,
                    .err => |e| return .{ .err = e },
                };

                return .{ .ok = .{ res[0], Self.from(res[1]) } };
            }
        }.f;
    }

    pub fn parse(allocator: mem.Allocator, input: []const u8) Result(Self) {
        _ = allocator;

        return alt(
            Self,
            &[_]*const fn (input: []const u8) Result(Self){
                Self.toExpr(NumLit, NumLit.parse),
            },
        )(input);
    }
};
