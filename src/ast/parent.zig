const std = @import("std");

const mem = std.mem;

const ast = @import("../ast.zig");
const expr = @import("expr.zig");
const lexer = @import("../lexer.zig");

const ErrorInfo = ast.ErrorInfo;
const InvalidInputError = ast.InvalidInputError;

const Token = lexer.Token;

const Expr = expr.Expr;

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
    err_info: ?*ErrorInfo,
) anyerror!Expr {
    var input_ = input.*;

    {
        if (input_.len == 0) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected '(', found nothing",
                ));
            }

            return error.InvalidInput;
        }

        const found_parent = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, "("),
            else => false,
        };

        if (!found_parent) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected '('",
                ));
            }

            return error.InvalidInput;
        }

        input_ = input_[1..];
    }

    const expr_ = try Expr.parse(
        allocator,
        &input_,
        err_info,
    );

    errdefer expr_.deinit();

    {
        if (input_.len == 0) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected ')', found nothing",
                ));
            }

            return error.InvalidInput;
        }

        const found_parent = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, ")"),
            else => false,
        };

        if (!found_parent) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected ')'",
                ));
            }

            return error.InvalidInput;
        }

        input_ = input_[1..];
    }

    input.* = input_;

    return expr_;
}
