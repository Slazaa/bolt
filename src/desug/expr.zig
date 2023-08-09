const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const ast = @import("../ast.zig");

const AstExpr = ast.expr.Expr;

pub const Bind = @import("expr/Bind.zig");
pub const File = @import("expr/File.zig");
pub const FnCall = @import("expr/FnCall.zig");
pub const FnDecl = @import("expr/FnDecl.zig");
pub const Ident = @import("expr/Ident.zig");
pub const Literal = @import("expr/literal.zig").Literal;
pub const NumLit = @import("expr/literal/NumLit.zig");

pub const Expr = union(enum) {
    const Self = @This();

    bind: Bind,
    file: File,
    fn_call: FnCall,
    fn_decl: FnDecl,
    ident: Ident,
    literal: Literal,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            Bind => .{ .bind = item },
            File => .{ .file = item },
            FnCall => .{ .fn_call = item },
            FnDecl => .{ .fn_decl = item },
            Ident => .{ .ident = item },
            Literal => .{ .literal = item },
            else => @compileError("Expected expr, found " ++ @typeName(T)),
        };
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .bind => |x| x.deinit(),
            .file => |x| x.deinit(),
            .fn_call => |x| x.deinit(),
            .fn_decl => |x| x.deinit(),
            else => {},
        }
    }

    pub fn desug(allocator: mem.Allocator, expr: AstExpr) Self {
        return switch (expr) {
            .bind => |x| Expr.from(Bind.desug(allocator, x)),
            .file => |x| Expr.from(File.desug(allocator, x)),
            .fn_call => |x| Expr.from(FnCall.desug(
                allocator,
                x,
            )),
            .fn_decl => |x| Expr.from(FnDecl.desug(
                allocator,
                x,
            )),
            .ident => |x| Expr.from(Ident.desug(x)),
            .literal => |x| Expr.from(Literal.desug(x)),
        };
    }

    pub fn format(
        self: Self,
        allocator: mem.Allocator,
        writer: Writer,
        depth: usize,
    ) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(allocator, writer, depth),
        }
    }
};
