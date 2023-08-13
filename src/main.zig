const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const ast = @import("ast.zig");
const desug = @import("desug.zig");
const eval = @import("eval.zig");
const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub fn main() !void {
    const input =
        \\pi = 3.1415;
        \\id = x -> x;
        \\id_pi = id pi;
    ;

    const stdout = io.getStdOut();
    const stderr = io.getStdErr();

    const stdout_writer = stdout.writer();
    const stderr_writer = stderr.writer();

    try stdout_writer.writeAll("--- Input ---\n");
    try stdout_writer.print("{s}\n\n", .{input});

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try stdout_writer.writeAll("--- Tokens ---\n");

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    if (lexer.lex(input, &tokens)) |err| {
        try err.format(stderr_writer);
        return error.LexerError;
    }

    for (tokens.items) |token| {
        try token.format(allocator, stdout_writer, 0);
    }

    try stdout_writer.writeAll("\n--- AST ---\n");

    var ast_ = switch (ast.parse(allocator, tokens.items)) {
        .ok => |x| x,
        .err => |e| {
            try e.format(stderr_writer);
            e.deinit();

            return;
        },
    };

    defer ast_.deinit();

    try ast_.format(allocator, stdout_writer, 0);

    try stdout_writer.writeAll("\n--- Desug ---\n");

    const desug_ = desug.desug(allocator, ast_);
    defer desug_.deinit();

    try desug_.format(allocator, stdout_writer, 0);

    try stdout_writer.writeAll("\n--- Eval ---\n");

    const eval_input = "id_pi";

    const result = switch (eval.eval(
        allocator,
        desug_,
        eval_input,
    )) {
        .ok => |x| x,
        .err => |e| {
            try e.format(stderr_writer);
            e.deinit();

            return;
        },
    };

    try stdout_writer.print("Input: {s}\n", .{eval_input});
    try stdout_writer.print("Result:\n", .{});

    try result.format(allocator, stdout_writer);
}
