const std = @import("std");

const debug = std.debug;
const fs = std.fs;
const heap = std.heap;
const io = std.io;
const math = std.math;
const mem = std.mem;
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

fn eval_(
    allocator: mem.Allocator,
    source_file: []const u8,
    input: []const u8,
) !void {
    const stdout = io.getStdOut();
    const stderr = io.getStdErr();

    const stdout_writer = stdout.writer();
    const stderr_writer = stderr.writer();

    var source = std.ArrayList(u8).init(allocator);
    defer source.deinit();

    {
        const file = try fs.cwd().openFile(source_file, .{});
        defer file.close();

        try file.reader().readAllArrayList(
            &source,
            math.maxInt(usize),
        );
    }

    try stdout_writer.writeAll("--- Source ---\n");
    try stdout_writer.print("{s}\n\n", .{source.items});

    try stdout_writer.writeAll("--- Tokens ---\n");

    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    {
        var err_info: LexerErrorInfo = undefined;

        lexer.lex(
            source.items,
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
            input,
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

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const stderr = io.getStdErr();
    const stderr_writer = stderr.writer();

    var args = try process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    const command = if (args.next()) |arg| arg else {
        try stderr_writer.print(
            "Expected command, found nothing\n",
            .{},
        );

        return error.InvalidCommand;
    };

    if (mem.eql(u8, command, "eval")) {
        const source_file = if (args.next()) |arg| arg else {
            try stderr_writer.print(
                "Expected source file, found nothing\n",
                .{},
            );

            return error.InvalidArgument;
        };

        const input = if (args.next()) |arg| arg else {
            try stderr_writer.print(
                "Expected input, found nothing\n",
                .{},
            );

            return error.InvalidArgument;
        };

        try eval_(allocator, source_file, input);
    } else {
        try stderr_writer.print(
            "Invalid command '{s}'\n",
            .{command},
        );

        return error.InvalidCommand;
    }
}
