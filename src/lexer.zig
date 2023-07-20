const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const ParserResult = @import("parser.zig").Result;
const Parser = @import("parser.zig").Parser;

pub const Ident = @import("lexer/Ident.zig");
pub const Keyword = @import("lexer/Keyword.zig");
pub const Literal = @import("lexer/Literal.zig");
pub const Punct = @import("lexer/Punct.zig");

pub const FormatError = error{
    CouldNotFormat,
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

    pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
        switch (self) {
            .ident => |x| try x.format(writer),
            .keyword => |x| try x.format(writer),
            .literal => |x| try x.format(writer),
            .punct => |x| try x.format(writer),
        }
    }
};

const whitespaces = " \t\n\r";

pub fn lexSkip(input: []const u8) []const u8 {
    var input_ = input;

    while (input_.len != 0) {
        if (mem.startsWith(u8, input_, "#")) {
            while (true) {
                const should_break = input_[0] == '\n';
                input_ = input_[1..];

                if (should_break) break;
            }
        }

        if (!mem.containsAtLeast(u8, whitespaces, 1, &[_]u8{input_[0]})) {
            break;
        }

        input_ = input_[1..];
    }

    return input_;
}

pub fn lex(input: []const u8, tokens: *std.ArrayList(Token)) ParserResult(void, void) {
    var input_ = input;

    while (input_.len != 0) {
        input_ = lexSkip(input_);

        const parsers = .{
            Keyword.lex,
            Literal.lex,
            Ident.lex,
            Punct.lex,
        };

        const res = b: inline for (parsers) |parser| {
            switch (parser(input_)) {
                .ok => |x| break :b .{ x[0], Token.from(x[1]) },
                .err => {},
            }
        } else {
            return .{ .err = .invalid_input };
        };

        input_ = res[0];
        const token = res[1];

        tokens.append(token) catch @panic("Could not append token");
    }

    return .{ .ok = .{ void{}, void{} } };
}
