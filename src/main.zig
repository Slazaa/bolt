const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const ast = @import("ast.zig");
const builtins = @import("builtins.zig");
const desug = @import("desug.zig");
const eval = @import("eval.zig");
const lexer = @import("lexer.zig");

const Token = lexer.Token;

const Bind = desug.expr.Bind;

pub fn main() !void {
    const input =
        \\fst = (x y -> x);
        \\sec = (x y -> y);
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

    if (try lexer.lex(input, &tokens)) |err| {
        try err.format(stderr_writer);
        return error.LexerError;
    }

    for (tokens.items) |token| {
        try token.format(allocator, stdout_writer, 0);
    }

    try stdout_writer.writeAll("\n--- AST ---\n");

    var ast_ = switch (try ast.parse(
        allocator,
        tokens.items,
    )) {
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

    const desug_ = try desug.desug(allocator, ast_);
    defer desug_.deinit();

    try desug_.format(allocator, stdout_writer, 0);

    try stdout_writer.writeAll("\n--- Eval ---\n");

    var builtins_ = std.ArrayList(Bind).init(allocator);

    defer {
        for (builtins_.items) |builtin| {
            builtin.deinit();
        }

        builtins_.deinit();
    }

    inline for (builtins.builtins) |builtin| {
        try builtins_.append(try builtin(allocator));
    }

    const eval_input = "+ 10 20";

    const result = switch (try eval.eval(
        builtins_,
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

    defer result.deinit();

    try stdout_writer.print("Input: {s}\n", .{eval_input});
    try stdout_writer.print("Result:\n", .{});

    try result.format(allocator, stdout_writer, 0);
}
