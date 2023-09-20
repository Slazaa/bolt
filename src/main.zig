const std = @import("std");

const debug = std.debug;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const process = std.process;

const ast = @import("ast.zig");
const builtin = @import("builtin.zig");
const builtins = @import("builtins.zig");
const eval = @import("eval.zig");
const expr = @import("expr.zig");
const lexer = @import("lexer.zig");

const AstErrorInfo = ast.ErrorInfo;
const AstExpr = ast.expr.Expr;

const EvalErrorInfo = eval.ErrorInfo;

const LexerErrorInfo = lexer.ErrorInfo;
const Token = lexer.Token;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var args = try process.argsWithAllocator(allocator);
    defer args.deinit();

    var input = std.ArrayList(u8).init(allocator);
    defer input.deinit();

    {
        const file = try fs.cwd().openFile("test.bolt", .{});
        defer file.close();

        try file.reader().readAllArrayList(
            &input,
            math.maxInt(usize),
        );
    }

    const stdout = io.getStdOut();
    const stderr = io.getStdErr();

    const stdout_writer = stdout.writer();
    const stderr_writer = stderr.writer();

    try stdout_writer.writeAll("--- Input ---\n");
    try stdout_writer.print("{s}\n\n", .{input.items});

    try stdout_writer.writeAll("--- Tokens ---\n");

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    {
        var err_info: LexerErrorInfo = undefined;

        lexer.lex(
            input.items,
            &tokens,
            &err_info,
        ) catch |err| {
            try err_info.format(stderr_writer);
            return err;
        };
    }

    for (tokens.items) |token| {
        try token.format(allocator, stdout_writer, 0);
    }

    try stdout_writer.writeAll("\n--- AST ---\n");

    var ast_ = b: {
        var err_info: AstErrorInfo = undefined;

        break :b ast.parse(
            allocator,
            tokens.items,
            &err_info,
        ) catch |err| {
            defer err_info.deinit();
            try err_info.format(stderr_writer);
            return err;
        };
    };

    defer ast_.deinit();

    try ast_.format(allocator, stdout_writer, 0);

    try stdout_writer.writeAll("\n--- Eval ---\n");

    var builtins_ = std.StringArrayHashMap(AstExpr).init(allocator);
    defer builtins_.deinit();

    defer {
        var builtins_iter = builtins_.iterator();

        while (builtins_iter.next()) |builtin_| {
            builtin_.value_ptr.deinit();
        }
    }

    inline for (builtins.builtins) |builtin_| {
        try builtins_.put(
            builtin_[0],
            try builtin.decl(allocator, builtin_[1]),
        );
    }

    const eval_input = "sec 10 x";

    const result = b: {
        var err_info: EvalErrorInfo = undefined;
        defer err_info.deinit();

        break :b eval.eval(
            builtins_,
            allocator,
            ast_,
            eval_input,
            &err_info,
        ) catch |err| {
            try err_info.format(stderr_writer);
            return err;
        };
    };

    defer result.deinit();

    try stdout_writer.print("Input: {s}\n", .{eval_input});
    try stdout_writer.print("Result:\n", .{});

    try result.format(allocator, stdout_writer, 0);
}
