const std = @import("std");

const mem = std.mem;

const ParserResult = @import("parser.zig").Result;

const alt = @import("parser.zig").alt;
const into = @import("parser.zig").into;

pub const Keyword = @import("lexer/Keyword.zig");

pub const Token = union(enum) {
    const Self = @This();

    keyword: Keyword,

    pub fn from(token: anytype) Self {
        const TokenT = @TypeOf(token);

        return switch (TokenT) {
            Keyword => .{ .keyword = token },
            else => @compileError("Expected token, found" ++ @typeName(TokenT)),
        };
    }
};

const whitespaces = " \t\n\r";

pub fn lex(input: []const u8, tokens: std.ArrayList(Token)) ParserResult(void) {
    var input_ = input;

    while (input_.len != 0) {
        if (mem.containsAtLeast(u8, whitespaces, 1, input_[0])) {
            input_ = input_[1..];
            continue;
        }

        const res = switch (alt(
            Token,
            &[_]*const fn (input: []const u8) ParserResult(Token){
                into(Keyword, Token, Keyword.lex, Token.from),
            },
        )(input)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        input_ = res[0];
        const token = res[1];

        tokens.append(token) catch @panic("Could not append to tokens");
    }

    return .{ .ok = .{ &[_]u8{}, void{} } };
}
