const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const ast = @import("../../ast.zig");
const lexer = @import("../../lexer.zig");

const ErrorInfo = ast.ErrorInfo;
const InvalidInputError = ast.InvalidInputError;

const Expr = ast.expr.Expr;
const Ident = ast.expr.Ident;

const Token = lexer.Token;
const IdentTok = lexer.Ident;

const Self = @This();

allocator: mem.Allocator,
ident: IdentTok,
args: std.ArrayList(Expr),
expr: *Expr,

pub fn deinit(self: Self) void {
    for (self.args.items) |arg| {
        arg.deinit();
    }

    self.args.deinit();

    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
    err_info: ?*ErrorInfo,
) !Self {
    var input_ = input.*;

    if (input_.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(InvalidInputError.init(
                allocator,
                "Expected Ident, found nothing",
            ));
        }

        return error.InvalidInput;
    }

    const ident = switch (input_[0]) {
        .ident => |x| x,
        else => {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected Ident",
                ));
            }

            return error.InvalidInput;
        },
    };

    input_ = input_[1..];

    var args = std.ArrayList(Expr).init(allocator);

    errdefer {
        for (args.items) |arg| {
            arg.deinit();
        }

        args.deinit();
    }

    while (true) {
        const parsers = .{
            Ident.parse,
        };

        const arg = inline for (parsers) |parser| {
            if (parser(allocator, input, null)) |arg| {
                break Expr.from(arg);
            } else |_| {}
        } else break;

        try args.append(arg);
    }

    if (input_.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInputError.init(
                allocator,
                "Expected '=', found nothing",
            ));
        }

        return error.InvalidInput;
    }

    {
        const found_eql = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, "="),
            else => false,
        };

        if (!found_eql) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected '='",
                ));
            }

            return error.InvalidInput;
        }

        input_ = input_[1..];
    }

    const expr = try allocator.create(Expr);
    errdefer allocator.destroy(expr);

    expr.* = try Expr.parse(
        allocator,
        &input_,
        err_info,
    );

    errdefer expr.deinit();

    if (input.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInputError.init(
                allocator,
                "Expected ';', found nothing",
            ));
        }

        return error.InvalidInput;
    }

    {
        const found_semi = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, ";"),
            else => false,
        };

        if (!found_semi) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "expected ';'",
                ));
            }

            return error.InvalidInput;
        }

        input_ = input_[1..];
    }

    input.* = input_;

    return .{
        .allocator = allocator,
        .ident = ident,
        .args = args,
        .expr = expr,
    };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
    depth: usize,
) fmt.Error!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    try fmt.addDepth(&depth_tabs, depth);

    try fmt.print(writer, "{s}Bind {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    ident: {s}\n", .{
        depth_tabs.items,
        self.ident.value,
    });

    try fmt.print(writer, "{s}    args: [\n", .{
        depth_tabs.items,
    });

    for (self.args.items) |arg| {
        try arg.format(allocator, writer, depth + 2);
    }

    try fmt.print(writer, "{s}    ]\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
