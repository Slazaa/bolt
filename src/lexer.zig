const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const Position = @import("Position.zig");

pub const Ident = @import("lexer/Ident.zig");
pub const Keyword = @import("lexer/Keyword.zig");
pub const Literal = @import("lexer/Literal.zig");
pub const Punct = @import("lexer/Punct.zig");

pub const InvalidTokenError = struct {
    const Self = @This();

    position: Position,

    pub fn init(position: Position) Self {
        return .{ .position = position };
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        try fmt.print(writer, "Invalid token at {}:{}\n", .{
            self.position.line,
            self.position.column,
        });
    }
};

pub const InvalidIndexingError = struct {
    const Self = @This();

    expected: usize,
    found: usize,

    pub fn init(expected: usize, found: usize) Self {
        return .{
            .expected = expected,
            .found = found,
        };
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        try fmt.print(
            writer,
            "Index mismatch, expected {}, found {}\n",
            .{
                self.expected,
                self.found,
            },
        );
    }
};

pub const ErrorInfo = union(enum) {
    const Self = @This();

    invalid_token: InvalidTokenError,
    index_mismatch: InvalidIndexingError,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            InvalidTokenError => .{ .invalid_token = item },
            InvalidIndexingError => .{ .index_mismatch = item },
            else => @compileError("Expected ErrorInfo, found" ++ @typeName(T)),
        };
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(writer),
        }
    }
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

        if (mem.eql(u8, old_input, input.*)) {
            break;
        }
    }
}

pub fn lex(
    input: []const u8,
    tokens: *std.ArrayList(Token),
    err_info: ?*ErrorInfo,
) !void {
    var input_ = input;
    var position = Position.default();

    while (input_.len != 0) {
        lexSkip(&input_, &position);

        const parsers = .{
            Keyword.lex,
            Punct.lex,
            Literal.lex,
            Ident.lex,
        };

        const token = inline for (parsers) |parser| {
            if (parser(&input_, &position)) |token| {
                break Token.from(token);
            }
        } else {
            if (err_info) |info| {
                info.* = ErrorInfo.from(InvalidTokenError.init(position));
            }

            return error.InvalidToken;
        };

        try tokens.append(token);
    }

    if (position.index != input.len) {
        if (err_info) |info| {
            info.* = ErrorInfo.from(InvalidIndexingError.init(
                input.len,
                position.index,
            ));
        }

        return error.InvalidIndexing;
    }
}
