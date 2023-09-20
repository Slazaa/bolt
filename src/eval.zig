const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const ast = @import("ast.zig");
const expr = @import("expr.zig");
const lexer = @import("lexer.zig");

const AstErrorInfo = ast.ErrorInfo;

const AstExpr = ast.expr.Expr;
const AstBind = ast.expr.Bind;
const AstFile = ast.expr.File;

const eval_expr = @import("eval/expr.zig");

const Expr = expr.Expr;

const LexerErrorInfo = lexer.ErrorInfo;
const Token = lexer.Token;

pub const InvalidInputError = struct {
    const Self = @This();

    message: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, message_slice: []const u8) !Self {
        var message = std.ArrayList(u8).init(allocator);
        errdefer message.deinit();

        try message.appendSlice(message_slice);

        return .{ .message = message };
    }

    pub fn deinit(self: Self) void {
        self.message.deinit();
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        try fmt.print(writer, "{s}\n", .{
            self.message.items,
        });
    }
};

pub const ErrorInfo = union(enum) {
    const Self = @This();

    lexer_error: LexerErrorInfo,
    expr_error: AstErrorInfo,
    invalid_input: InvalidInputError,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            LexerErrorInfo => .{ .lexer_error = item },
            AstErrorInfo => .{ .expr_error = item },
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

pub const Scope = std.StringArrayHashMap(AstExpr);

pub fn eval(
    builtins: std.StringArrayHashMap(AstExpr),
    allocator: mem.Allocator,
    file: AstFile,
    input: []const u8,
    err_info: ?*ErrorInfo,
) !Expr {
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    {
        var err_info_: LexerErrorInfo = undefined;

        lexer.lex(
            input,
            &tokens,
            &err_info_,
        ) catch |err| {
            if (err_info) |info| info.* = ErrorInfo.from(err_info_);
            return err;
        };
    }

    var tokens_ = tokens.items;

    var expr_ = b: {
        var err_info_: AstErrorInfo = undefined;

        break :b AstExpr.parse(
            allocator,
            &tokens_,
            &err_info_,
        ) catch |err| {
            if (err_info) |info| info.* = ErrorInfo.from(err_info_);
            return err;
        };
    };

    defer expr_.deinit();

    var scope = Scope.init(allocator);
    defer scope.deinit();

    {
        var iter = builtins.iterator();

        while (iter.next()) |entry| {
            try scope.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }

    for (file.binds.items) |bind| {
        try scope.put(bind.ident.value, bind.expr.*);
    }

    return try eval_expr.eval(
        allocator,
        scope,
        expr_,
        err_info,
    );
}
