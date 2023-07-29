const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const BindMap = @import("BindMap.zig");

const eval = @import("eval.zig");
const expr = @import("expr.zig");
const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub fn main() !void {
    const input =
        \\pi = 3.1415;
    ;

    const stdout = io.getStdOut();
    const stdout_writer = stdout.writer();

    try stdout_writer.writeAll("--- Input ---\n");
    try stdout_writer.print("{s}\n\n", .{input});

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    try stdout_writer.writeAll("--- Tokens ---\n");

    switch (lexer.lex(allocator, input, &tokens)) {
        .ok => {},
        .err => |e| {
            try e.format(stdout_writer);
            e.deinit();

            return;
        },
    }

    for (tokens.items) |token| {
        try token.format(stdout_writer);
    }

    try stdout_writer.writeAll("\n--- Bindings Map ---\n");

    const bind_map = switch (BindMap.map(allocator, tokens.items)) {
        .ok => |x| x[1],
        .err => |e| {
            try e.format(stdout_writer);
            e.deinit();

            return;
        },
    };

    defer bind_map.deinit();

    try bind_map.format(stdout_writer);

    try stdout_writer.writeAll("\n--- AST ---\n");

    var ast = switch (expr.File.parse(allocator, tokens.items)) {
        .ok => |x| x[1],
        .err => return error.ASTError,
    };

    defer ast.deinit();

    try ast.format(allocator, stdout_writer, 0);

    // try stdout_writer.writeAll("\n--- Eval ---\n");
}
