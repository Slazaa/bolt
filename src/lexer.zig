const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const ParserResult = @import("parser.zig").Result;

const Parser = @import("parser.zig").Parser;

const Position = @import("Position.zig");

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

pub fn InputResult(comptime T: type) type {
    return struct { T, Position };
}

const whitespaces = " \n\r";

pub fn lexSkip(input: []const u8, position: Position) InputResult([]const u8) {
    var input_ = input;
    var position_ = position;

    while (input_.len != 0) {
        // Skip comment
        if (mem.startsWith(u8, input_, "#")) {
            while (true) {
                const should_break = input_[0] == '\n';

                position_.index += 1;
                input_ = input_[1..];

                if (should_break) break;
            }

            position_.column = 0;
            position_.line += 1;
        }

        // Skip whitespace
        if (mem.containsAtLeast(u8, whitespaces, 1, &[_]u8{input_[0]})) {
            if (input_[0] == '\n') {
                position_.column = 0;
                position_.line += 1;
            } else {
                position_.column += 1;
            }

            position_.index += 1;
            input_ = input_[1..];

            continue;
        }

        break;
    }

    return .{ input_, position_ };
}

pub fn lex(allocator: mem.Allocator, input: []const u8, tokens: *std.ArrayList(Token)) ParserResult(void, void) {
    var input_ = input;

    var position = Position{
        .line = 0,
        .column = 0,
        .index = 0,
    };

    while (input_.len != 0) {
        const res = lexSkip(input_, position);

        input_ = res[0];
        position = res[1];

        const parsers = .{
            Keyword.lex,
            Literal.lex,
            Ident.lex,
            Punct.lex,
        };

        const token = b: inline for (parsers) |parser| {
            switch (parser(input_, position)) {
                .ok => |x| {
                    input_ = x[0][0];
                    position = x[0][1];

                    break :b Token.from(x[1]);
                },
                .err => {},
            }
        } else {
            var message = std.ArrayList(u8).init(allocator);
            message.appendSlice("Invalid token") catch return .{ .err = .{ .allocation_failed = void{} } };

            return .{ .err = .{ .invalid_input = .{ .message = message } } };
        };

        tokens.append(token) catch return .{ .err = .{ .allocation_failed = void{} } };
    }

    if (position.index != input.len) {
        var message = std.ArrayList(u8).init(allocator);
        message.appendSlice("Index does not match input size") catch return .{ .err = .{ .allocation_failed = void{} } };

        return .{ .err = .{ .invalid_input = .{ .message = message } } };
    }

    return .{ .ok = .{ void{}, void{} } };
}
