const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../fmt.zig");

const lexer = @import("../lexer.zig");

const Token = lexer.Token;

const ast = @import("../ast.zig");

const Result = ast.Result;
const Error = ast.Error;
const InvalidInputError = ast.InvalidInputError;

pub const Bind = @import("expr/Bind.zig");
pub const File = @import("expr/File.zig");
pub const FnCall = @import("expr/FnCall.zig");
pub const FnDecl = @import("expr/FnDecl.zig");
pub const Ident = @import("expr/Ident.zig");
pub const Literal = @import("expr/literal.zig").Literal;
pub const NumLit = @import("expr/literal/NumLit.zig");

pub const parent = @import("parent.zig");

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

    pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Expr) {
        if (input.len == 0) {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Expected Expr, found nothing",
            )) };
        }

        const parsers = .{
            Literal.parse,
            FnDecl.parse,
            Ident.parse,
        };

        var exprs = std.ArrayList(Expr).init(allocator);
        defer exprs.deinit();

        expr_loop: while (input.len != 0) {
            const expr = b: {
                switch (parent.parse(allocator, input)) {
                    .ok => |x| break :b x,
                    .err => |e| e.deinit(),
                }

                inline for (parsers) |parser| {
                    switch (parser(allocator, input)) {
                        .ok => |x| break :b Self.from(x),
                        .err => |e| e.deinit(),
                    }
                } else {
                    break :expr_loop;
                }
            };

            exprs.append(expr) catch @panic("Allocation failed");
        }

        while (exprs.items.len != 1) {
            const func = exprs.items[0];
            const expr = exprs.orderedRemove(1);

            exprs.items[0] = switch (FnCall.parse(
                allocator,
                func,
                expr,
            )) {
                .ok => |x| Self.from(x),
                .err => |e| return .{ .err = e },
            };
        }

        return .{ .ok = exprs.items[0] };
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
