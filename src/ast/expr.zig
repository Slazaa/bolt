const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const ast = @import("../ast.zig");
const lexer = @import("../lexer.zig");

const ErrorInfo = ast.ErrorInfo;
const InvalidInputError = ast.InvalidInputError;

const Token = lexer.Token;

pub const Bind = @import("expr/Bind.zig");
pub const File = @import("expr/File.zig");
pub const FnCall = @import("expr/FnCall.zig");
pub const FnDecl = @import("expr/FnDecl.zig");
pub const Ident = @import("expr/Ident.zig");

pub const Literal = @import("expr/literal.zig").Literal;
pub const NumLit = @import("expr/literal/NumLit.zig");

pub const NatFn = @import("expr/NatFn.zig");

pub const parent = @import("parent.zig");

pub const Expr = union(enum) {
    const Self = @This();

    bind: Bind,
    file: File,
    fn_call: FnCall,
    fn_decl: FnDecl,
    ident: Ident,
    literal: Literal,
    nat_fn: NatFn,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            Bind => .{ .bind = item },
            File => .{ .file = item },
            FnCall => .{ .fn_call = item },
            FnDecl => .{ .fn_decl = item },
            Ident => .{ .ident = item },
            Literal => .{ .literal = item },
            NatFn => .{ .nat_fn = item },
            else => @panic("Expected Expr, found " ++ @typeName(T)),
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

    pub fn parse(
        allocator: mem.Allocator,
        input: *[]const Token,
        err_info: ?*ErrorInfo,
    ) !Expr {
        if (input.len == 0) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(InvalidInputError.init(
                    allocator,
                    "Expected Expr, found nothing",
                ));
            }

            return error.InvalidInput;
        }

        const parsers = .{
            Literal.parse,
            FnDecl.parse,
            Ident.parse,
        };

        var exprs = std.ArrayList(Expr).init(allocator);
        defer exprs.deinit();

        errdefer {
            for (exprs.items) |expr| {
                expr.deinit();
            }
        }

        expr_loop: while (input.len != 0) {
            const expr = b: {
                if (parent.parse(
                    allocator,
                    input,
                    null,
                )) |expr_| {
                    break :b expr_;
                } else |_| {}

                inline for (parsers) |parser| {
                    if (parser(allocator, input, null)) |expr_| {
                        break :b Self.from(expr_);
                    } else |_| {}
                }

                break :expr_loop;
            };

            try exprs.append(expr);
        }

        if (exprs.items.len == 0) {
            if (err_info) |info| {
                info.* = ErrorInfo.from(try InvalidInputError.init(
                    allocator,
                    "Could not make Expr",
                ));
            }

            return error.InvalidInput;
        }

        while (exprs.items.len > 1) {
            const func = exprs.items[0];
            const expr = exprs.orderedRemove(1);

            exprs.items[0] = Self.from(try FnCall.parse(
                allocator,
                func,
                expr,
            ));
        }

        return exprs.items[0];
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
