const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const lexer = @import("../lexer.zig");

const Result = ast.Result;
const Error = ast.Error;
const InvalidInputError = ast.InvalidInputError;

const Token = lexer.Token;

const Expr = @import("expr.zig").Expr;

pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Expr) {
    var input_ = input.*;

    if (input_.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected '(', found nothing",
        )) };
    }

    switch (input_[0]) {
        .punct => |x| if (!mem.eql(u8, x.value, "(")) {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected '('",
            )) };
        },
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected '('",
        )) },
    }

    input_ = input_[1..];

    const expr = switch (Expr.parse(allocator, &input_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    if (input_.len == 0) {
        return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected ')', found nothing",
        )) };
    }

    switch (input_[0]) {
        .punct => |x| if (!mem.eql(u8, x.value, ")")) {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected ')'",
            )) };
        },
        else => return .{ .err = Error.from(InvalidInputError.init(
            allocator,
            "Expected ')'",
        )) },
    }

    input_ = input_[1..];

    input.* = input_;

    return .{ .ok = expr };
}
