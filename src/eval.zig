const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const ast = @import("ast.zig");
const desug = @import("desug.zig");
const lexer = @import("lexer.zig");

const AstExpr = ast.expr.Expr;

const DesugExpr = desug.expr.Expr;
const DesugFile = desug.expr.File;

const eval_expr = @import("eval/expr.zig");

const expr = @import("expr.zig");

const Expr = expr.Expr;

const Token = lexer.Token;

pub const InvalidInputError = struct {
    const Self = @This();

    message: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, message_slice: []const u8) !Self {
        var message = std.ArrayList(u8).init(allocator);
        try message.appendSlice(message_slice);

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

pub const Scope = std.StringArrayHashMap(DesugExpr);

pub fn Result(comptime T: type) type {
    return union(enum) {
        ok: T,
        err: Error,
    };
}

pub fn eval(
    allocator: mem.Allocator,
    file: DesugFile,
    input: []const u8,
) !Result(Expr) {
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    if (try lexer.lex(input, &tokens)) |err| {
        return .{ .err = Error.from(err) };
    }

    var tokens_ = tokens.items;

    var expr_ = switch (try AstExpr.parse(
        allocator,
        &tokens_,
    )) {
        .ok => |x| x,
        .err => |e| return .{ .err = Error.from(e) },
    };

    defer expr_.deinit();

    const desug_expr = try DesugExpr.desug(allocator, expr_);
    defer desug_expr.deinit();

    var scope = Scope.init(allocator);
    defer scope.deinit();

    for (file.binds.items) |bind| {
        scope.put(bind.ident.value, bind.expr.*) catch {
            @panic("Put failed");
        };
    }

    return try eval_expr.eval(
        allocator,
        scope,
        desug_expr,
    );
}
