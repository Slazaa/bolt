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

const Token = lexer.Token;
const IdentTok = lexer.Ident;

const Self = @This();

allocator: mem.Allocator,
arg: IdentTok,
expr: *Expr,

pub fn deinit(self: Self) void {
    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn parse(
    allocator: mem.Allocator,
    input: *[]const Token,
    err_info: ?*ErrorInfo,
) anyerror!Self {
    var input_ = input.*;

    var args = std.ArrayList(IdentTok).init(allocator);
    defer args.deinit();

    while (input_.len != 0) {
        const arg = switch (input_[0]) {
            .ident => |x| x,
            else => break,
        };

        try args.append(arg);

        input_ = input_[1..];
    }

    if (args.items.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInputError.init(
                allocator,
                "Expected at least 1 arg, found nothing",
            ));
        }

        return error.InvalidInput;
    }

    if (input_.len == 0) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(try InvalidInputError.init(
                allocator,
                "Expected '->', found nothing",
            ));
        }

        return error.InvalidInput;
    }

    {
        const found_slice = switch (input_[0]) {
            .punct => |x| mem.eql(u8, x.value, "->"),
            else => false,
        };

        if (!found_slice) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Expected '->'",
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

    var curr_expr = expr;

    for (args.items[1..]) |arg| {
        const new_curr_expr = try allocator.create(Expr);
        errdefer allocator.destroy(new_curr_expr);

        new_curr_expr.* = Expr.from(Self{
            .allocator = allocator,
            .arg = arg,
            .expr = curr_expr,
        });

        curr_expr = new_curr_expr;
    }

    input.* = input_;

    return .{
        .allocator = allocator,
        .arg = args.items[0],
        .expr = curr_expr,
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

    try fmt.print(writer, "{s}FnDecl: {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    args: [\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}        {s}\n", .{
        depth_tabs.items,
        self.arg.value,
    });

    try fmt.print(writer, "{s}    ]\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
