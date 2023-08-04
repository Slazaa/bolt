const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Position = @import("Position.zig");

pub const Ident = @import("lexer/Ident.zig");
pub const Keyword = @import("lexer/Keyword.zig");
pub const Literal = @import("lexer/Literal.zig");
pub const Punct = @import("lexer/Punct.zig");

pub const InvalidTokenError = struct {
    position: Position,
};

pub const Error = union(enum) {
    invalid_token: InvalidTokenError,
    invalid_indexing: void,
};

pub const Token = union(enum) {
    const Self = @This();

    ident: Ident,
    keyword: Keyword,
    literal: Literal,
    punct: Punct,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            Ident => .{ .ident = item },
            Keyword => .{ .keyword = item },
            Literal => .{ .literal = item },
            Punct => .{ .punct = item },
            else => @compileError("Expected token, found" ++ @typeName(T)),
        };
    }

    pub fn format(self: Self, writer: fs.File.Writer) void {
        switch (self) {
            inline else => |x| x.format(writer),
        }
    }
};

fn skipComment(input: *[]const u8, position: *Position) void {
    if (!mem.startsWith(u8, input.*, "#")) {
        return;
    }

    while (true) {
        input.* = input.*[1..];
        position.index += 1;

        if (input.*[0] == '\n') {
            position.column = 1;
            position.line += 1;

            break;
        }
    }
}

fn skipWhitespaces(input: *[]const u8, position: *Position) void {
    const whitespaces = " \n\r";

    while (mem.containsAtLeast(
        u8,
        whitespaces,
        1,
        &[_]u8{input.*[0]},
    )) {
        if (input.*[0] == '\n') {
            position.column = 1;
            position.line += 1;
        } else {
            position.column += 1;
        }

        position.index += 1;
        input.* = input.*[1..];
    }
}

fn lexSkip(input: *[]const u8, position: *Position) void {
    var old_input: []const u8 = undefined;

    while (true) {
        old_input = input.*;

        skipComment(input, position);
        skipWhitespaces(input, position);

        if (old_input.len == input.len and old_input.ptr == input.ptr) {
            break;
        }
    }

    return;
}

pub fn lex(input: []const u8, tokens: *std.ArrayList(Token)) ?Error {
    var input_ = input;
    var position = Position.default();

    while (input_.len != 0) {
        lexSkip(&input_, &position);

        const parsers = .{
            Keyword.lex,
            Literal.lex,
            Ident.lex,
            Punct.lex,
        };

        const token = inline for (parsers) |parser| {
            if (parser(&input_, &position)) |token| {
                break Token.from(token);
            }
        } else {
            return .{ .invalid_token = .{ .position = position } };
        };

        tokens.append(token) catch @panic("Allocation failed");
    }

    if (position.index != input.len) {
        return .invalid_indexing;
    }

    return null;
}
