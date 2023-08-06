const std = @import("std");

const mem = std.mem;

const ast = @import("../../ast.zig");
const lexer = @import("../../lexer.zig");

const AstFnDecl = ast.FnDecl;

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

pub fn desug(allocator: mem.Allocator, fn_decl: AstFnDecl) Self {
    _ = fn_decl;
    _ = allocator;
}
