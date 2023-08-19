const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const ast = @import("../../ast.zig");
const lexer = @import("../../lexer.zig");

const AstFnDecl = ast.expr.FnDecl;

const IdentTok = lexer.Ident;

const expr = @import("../expr.zig");

const Expr = expr.Expr;

const Self = @This();

allocator: mem.Allocator,
arg: IdentTok,
expr: *Expr,

pub fn deinit(self: Self) void {
    self.expr.deinit();
    self.allocator.destroy(self.expr);
}

pub fn desug(allocator: mem.Allocator, fn_decl: AstFnDecl) !Self {
    if (fn_decl.args.items.len == 0) {
        @panic("Expected at least 1 arg, found none");
    }

    var last_fn_decl: ?Self = null;

    var i = fn_decl.args.items.len - 1;

    while (i >= 0) : (i -= 1) {
        const arg = fn_decl.args.items[i];

        if (last_fn_decl) |last_fn_decl_| {
            const expr_ = try allocator.create(Expr);
            expr_.* = Expr.from(last_fn_decl_);

            last_fn_decl = .{
                .allocator = allocator,
                .arg = arg,
                .expr = expr_,
            };
        } else {
            const expr_ = try allocator.create(Expr);
            expr_.* = try Expr.desug(allocator, fn_decl.expr.*);

            last_fn_decl = .{
                .allocator = allocator,
                .arg = arg,
                .expr = expr_,
            };
        }

        if (i == 0) {
            break;
        }
    }

    return last_fn_decl.?;
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

    try fmt.print(writer, "{s}FnDecl {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    arg: {s}\n", .{
        depth_tabs.items,
        self.arg.value,
    });

    try fmt.print(writer, "{s}    expr:\n", .{
        depth_tabs.items,
    });

    try self.expr.format(allocator, writer, depth + 2);

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
