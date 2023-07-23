const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const expr = @import("expr.zig");
const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub fn main() !void {
    const input =
        \\let x = 10.25
        \\let y = x
    ;

    const stdout = io.getStdOut();
    const stdout_writer = stdout.writer();

    try stdout_writer.writeAll("--- Input ---\n");
    try stdout_writer.print("{s}\n", .{input});

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    switch (lexer.lex(input, &tokens)) {
        .ok => {},
        .err => return error.LexerError,
    }

    try stdout_writer.writeAll("\n--- Tokens ---\n");

    for (tokens.items) |token| {
        try token.format(stdout_writer);
    }

    try stdout_writer.writeAll("\n--- AST ---\n");

    var ast = switch (expr.File.parse(allocator, tokens.items)) {
        .ok => |x| x[1],
        .err => return error.ASTError,
    };

    defer ast.deinit();

    try ast.format(allocator, stdout_writer, 0);
}
