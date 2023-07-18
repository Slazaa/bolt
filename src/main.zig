const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const expr = @import("expr.zig");
const lexer = @import("lexer.zig");

pub fn main() !void {
    const input =
        \\51
    ;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var tokens = std.ArrayList(lexer.Token).init(allocator);
    defer tokens.deinit();

    switch (lexer.lex(input, &tokens)) {
        .ok => {},
        .err => return error.LexerError,
    }

    const stdout = io.getStdOut();
    const stdout_writer = stdout.writer();

    for (tokens.items) |token| {
        try token.format(stdout_writer);
    }

    // var ast = switch (expr.File.parse(allocator, tokens.items)) {
    //     .ok => |x| x[1],
    //     .err => return error.ASTError,
    // };

    // defer ast.deinit();

    // try ast.format(allocator, stdout_writer, 0);
}
