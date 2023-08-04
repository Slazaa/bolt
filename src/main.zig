const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub fn main() !void {
    const input =
        \\pi = 3.1415;
        \\id x = x;
    ;

    const stdout = io.getStdOut();
    const stdout_writer = stdout.writer();

    try stdout_writer.writeAll("--- Input ---\n");
    try stdout_writer.print("{s}\n\n", .{input});

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try stdout_writer.writeAll("--- Tokens ---\n");

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    if (lexer.lex(input, &tokens)) |_| {
        return error.LexerError;
    }

    for (tokens.items) |token| {
        token.format(stdout_writer);
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
