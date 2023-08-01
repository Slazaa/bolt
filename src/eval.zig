const std = @import("std");

const mem = std.mem;

const Expr = @import("expr.zig").Expr;
const File = @import("expr.zig").File;

const lexer = @import("lexer.zig");

const exprEval = @import("eval/expr.zig").eval;

const Token = lexer.Token;

pub fn eval(
    comptime T: type,
    allocator: mem.Allocator,
    file: File,
    input: []const u8,
) !T {
    _ = file;

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    switch (lexer.lex(allocator, input, &tokens)) {
        .ok => {},
        .err => |e| {
            e.deinit();
            return error.LexerFailed;
        },
    }

    var expr = switch (Expr.parse(allocator, tokens.items)) {
        .ok => |x| x[1],
        .err => |e| {
            e.deinit();
            return error.ExprFailed;
        },
    };

    defer expr.deinit();

    return exprEval(T, file, expr);
}
