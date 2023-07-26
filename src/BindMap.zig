const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("expr.zig");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

const Literal = expr.Literal;
const Ident = expr.Ident;

const Token = lexer.Token;

const ParserResult = parser.Result;

const Self = @This();

const FormatError = error{
    CouldNotFormat,
};

const Map = struct {
    ident: Ident,
    args: std.ArrayList(Literal),

    pub fn deinit(self: Map) void {
        self.args.deinit();
    }

    pub fn format(self: Map, writer: fs.File.Writer) FormatError!void {
        writer.print("- {s} ", .{self.ident.value.value}) catch return error.CouldNotFormat;

        for (self.args.items) |arg| {
            switch (arg) {
                .num => |x| writer.print("{s}", .{x.value.value}) catch return error.CouldNotFormat,
            }
        }

        writer.writeAll("\n") catch return error.CouldNotFormat;
    }
};

binds: std.ArrayList(Map),

pub fn deinit(self: Self) void {
    for (self.binds.items) |bind| {
        bind.deinit();
    }

    self.binds.deinit();
}

pub fn map(allocator: mem.Allocator, input: []const Token) ParserResult([]const Token, Self) {
    var input_ = input;

    var self = Self{
        .binds = std.ArrayList(Map).init(allocator),
    };

    while (input_.len != 0) {
        const ident = b: {
            const res = switch (Ident.parse(allocator, input_)) {
                .ok => |x| x,
                .err => {
                    self.deinit();
                    return .{ .err = .invalid_input };
                },
            };

            input_ = res[0];

            break :b res[1];
        };

        var args = std.ArrayList(Literal).init(allocator);

        while (true) {
            switch (input_[0]) {
                .punct => |x| if (mem.eql(u8, x.value, "=")) break,
                else => {},
            }

            const res = switch (Literal.parse(allocator, input_)) {
                .ok => |x| x,
                .err => {
                    self.deinit();
                    return .{ .err = .invalid_input };
                },
            };

            input_ = res[0];
        }

        self.binds.append(Map{
            .ident = ident,
            .args = args,
        }) catch {
            @panic("Failed appening bind");
        };

        while (true) {
            if (input_.len == 0) {
                self.deinit();
                return .{ .err = .invalid_input };
            }

            switch (input_[0]) {
                .punct => |x| if (!mem.eql(u8, x.value, ";")) break,
                else => {},
            }

            input_ = input_[1..];
        }
    }

    return .{ .ok = .{ input_, self } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    for (self.binds.items) |bind| {
        try bind.format(writer);
    }
}
