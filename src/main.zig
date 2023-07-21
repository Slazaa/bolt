const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const expr = @import("expr.zig");
const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub fn main() !void {
    const input =
        \\let x;
    ;

    const stdout = io.getStdOut();
    const stdout_writer = stdout.writer();

    try stdout_writer.writeAll("--- Input ---\n");
    try stdout_writer.print("{s}\n", .{input});

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

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

    var ast = switch (expr.File.parse(allocator, tokens.items)) {
        .ok => |x| x[1],
        .err => return error.ASTError,
    };

    defer ast.deinit();

    try stdout_writer.writeAll("\n--- AST ---\n");
    try ast.format(allocator, stdout_writer, 0);
}
