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
            else => @compileError("Expected Expr, found " ++ @typeName(T)),
        };
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .bind => |x| x.deinit(),
            .file => |x| x.deinit(),
            .fn_decl => |x| x.deinit(),
            else => {},
        }
    }

    pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Expr) {
        const parsers = .{
            Literal.parse,
            FnDecl.parse,
            FnCall.parse,
            Ident.parse,
        };

        const expr = inline for (parsers) |parser| {
            switch (parser(allocator, input)) {
                .ok => |x| break Self.from(x),
                .err => |e| e.deinit(),
            }
        } else {
            return .{ .err = Error.from(InvalidInputError.init(
                allocator,
                "Could not parse Expr",
            )) };
        };

        return .{ .ok = expr };
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
