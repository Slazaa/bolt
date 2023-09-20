const std = @import("std");

const fmt = std.fmt;
const mem = std.mem;

const ast = @import("ast.zig");

const AstExpr = ast.expr.Expr;
const AstFnDecl = ast.expr.FnDecl;
const AstNatFn = ast.expr.NatFn;

const Position = @import("Position.zig");

pub fn decl(allocator: mem.Allocator, func: anytype) !AstExpr {
    const T = @TypeOf(func);

    switch (@typeInfo(T)) {
        .Fn => |X| {
            var last_expr = AstExpr.from(AstNatFn{ .func = func });
            errdefer last_expr.deinit();

            inline for (X.params, 0..) |_, idx| {
                var expr = try allocator.create(AstExpr);
                errdefer allocator.destroy(expr);

                expr.* = last_expr;

                const idxBytes = fmt.comptimePrint("{}", .{idx});

                last_expr = AstExpr.from(AstFnDecl{
                    .allocator = allocator,
                    .arg = .{
                        .value = "_" ++ idxBytes,
                        .start_pos = Position.default(),
                        .end_pos = Position.default(),
                    },
                    .expr = expr,
                });
            }

            return last_expr;
        },
        else => @compileError("Expected function, found" ++ @typeName(T)),
    }
}
