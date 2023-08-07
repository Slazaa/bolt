const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const ast = @import("../ast.zig");

const AstExpr = ast.expr.Expr;

pub const Bind = @import("expr/Bind.zig");
pub const File = @import("expr/File.zig");
pub const FnDecl = @import("expr/FnDecl.zig");

pub const Expr = union(enum) {
    const Self = @This();

    bind: Bind,
    file: File,
    fn_decl: FnDecl,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        switch (T) {
            Bind => .{ .bind = item },
            File => .{ .file = item },
            FnDecl => .{ .fn_decl = item },
            else => @compileError("Expected expr, found " ++ @typeName(T)),
        }
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .bind => |x| x.deinit(),
            .file => |x| x.deinit(),
            .fn_decl => |x| x.deinit(),
        }
    }

    pub fn desug(allocator: mem.Allocator, expr: AstExpr) Self {
        return switch (expr) {
            .bind => |x| Expr.from(Bind.desug(allocator, x)),
            .file => |x| Expr.from(File.desug(allocator, x)),
            .fn_decl => |x| Expr.from(FnDecl.desug(allocator, x)),
            else => @compileError("Not supported yet"),
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
