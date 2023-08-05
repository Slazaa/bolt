const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub fn main() !void {
    const input =
        \\pi = 3.1415;
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
        err.format(stderr_writer);
        return error.LexerError;
    }

    for (tokens.items) |token| {
        token.format(allocator, stdout_writer, 0);
    }

    // try stdout_writer.writeAll("\n--- AST ---\n");

    // var ast = switch (expr.File.parse(
    //     allocator,
    //     tokens.items,
    // )) {
    //     .ok => |x| x[1],
    //     .err => return error.ASTError,
    // };

    // defer ast.deinit();

    // try ast.format(allocator, stdout_writer, 0);

    // try stdout_writer.writeAll("\n--- Eval ---\n");

    // const eval_input = "pi";
    // const result = try eval.eval(
    //     f64,
    //     allocator,
    //     ast,
    //     eval_input,
    // );

    // try stdout_writer.print("Input: {s}\n", .{eval_input});
    // try stdout_writer.print("Result: {}\n", .{result});
}
