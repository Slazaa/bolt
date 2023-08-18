const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const lexer = @import("../lexer.zig");

const Result = ast.Result;
const Error = ast.Error;
const InvalidInputError = ast.InvalidInputError;

const Token = lexer.Token;

const Expr = @import("expr.zig").Expr;

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
) anyerror!Result(Expr) {
    var input_ = input.*;

    {
        if (input_.len == 0) {
            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected '(', found nothing",
            )) };
        }

        const found_parent = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, "("),
            else => false,
        };

        if (!found_parent) {
            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected '('",
            )) };
        }

        input_ = input_[1..];
    }

    const expr = switch (try Expr.parse(allocator, &input_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    errdefer expr.deinit();

    {
        if (input_.len == 0) {
            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected ')', found nothing",
            )) };
        }

        const found_parent = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, ")"),
            else => false,
        };

        if (!found_parent) {
            expr.deinit();

            return .{ .err = Error.from(try InvalidInputError.init(
                allocator,
                "Expected ')'",
            )) };
        }

        input_ = input_[1..];
    }

    input.* = input_;

    return .{ .ok = expr };
}
