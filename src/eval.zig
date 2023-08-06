const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

const Expr = ast.expr.Expr;
const File = ast.expr.File;

const eval_expr = @import("eval/expr.zig");

const Token = lexer.Token;

pub const InvalidInputError = struct {
    const Self = @This();

    message: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, message_slice: []const u8) Self {
        var message = std.ArrayList(u8).init(allocator);
        message.appendSlice(message_slice) catch @panic("Allocation failed");

        return .{
            .message = message,
        };
    }

    pub fn deinit(self: Self) void {
        self.message.deinit();
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        try fmt.print(writer, "Invalid input: {s}\n", .{
            self.message.items,
        });
    }
};

pub const Error = union(enum) {
    const Self = @This();

    lexer_error: lexer.Error,
    expr_error: ast.Error,
    invalid_input: InvalidInputError,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            lexer.Error => .{ .lexer_error = item },
            ast.Error => .{ .expr_error = item },
            InvalidInputError => .{ .invalid_input = item },
            else => @compileError("Expected error, found " ++ @typeName(T)),
        };
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .expr_error => |x| x.deinit(),
            .invalid_input => |x| x.deinit(),
            else => {},
        }
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(writer),
        }
    }
};

pub fn Result(comptime T: type) type {
    return union(enum) {
        ok: T,
        err: Error,
    };
}

pub fn eval(
    comptime T: type,
    allocator: mem.Allocator,
    file: File,
    input: []const u8,
) Result(T) {
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    if (lexer.lex(input, &tokens)) |err| {
        return .{ .err = Error.from(err) };
    }

    var tokens_ = tokens.items;

    var expr_ = switch (Expr.parse(allocator, &tokens_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = Error.from(e) },
    };

    defer expr_.deinit();

    return eval_expr.eval(T, file, expr_);
}
