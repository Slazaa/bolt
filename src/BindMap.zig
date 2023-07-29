const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const expr = @import("expr.zig");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");

const Expr = expr.Expr;
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
    args: std.ArrayList(Expr),

    pub fn deinit(self: Map) void {
        self.args.deinit();
    }

    pub fn format(self: Map, writer: fs.File.Writer) FormatError!void {
        writer.print("- {s} ", .{self.ident.value.value}) catch return error.CouldNotFormat;

        for (self.args.items) |arg| {
            switch (arg) {
                .ident => |x| writer.writeAll(x.value.value) catch return error.CouldNotFormat,
                else => @panic("Invalid arg type"),
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
                .err => |e| {
                    self.deinit();
                    return .{ .err = e };
                },
            };

            input_ = res[0];

            break :b res[1];
        };

        var args = std.ArrayList(Expr).init(allocator);

        while (true) {
            switch (input_[0]) {
                .punct => |x| if (mem.eql(u8, x.value, "=")) break,
                else => {},
            }

            const res = switch (Ident.parse(allocator, input_)) {
                .ok => |x| .{ x[0], Expr.from(x[1]) },
                .err => |e| {
                    e.deinit();
                    self.deinit();

                    var message = std.ArrayList(u8).init(allocator);
                    message.appendSlice("Could not parse argument") catch return .{ .err = .{ .allocation_failed = void{} } };

                    return .{ .err = .{ .invalid_input = .{ .message = message } } };
                },
            };

            input_ = res[0];

            args.append(res[1]) catch return .{ .err = .{ .allocation_failed = void{} } };
        }

        self.binds.append(Map{
            .ident = ident,
            .args = args,
        }) catch return .{ .err = .{ .allocation_failed = void{} } };

        while (true) {
            if (input_.len == 0) {
                self.deinit();

                var message = std.ArrayList(u8).init(allocator);
                message.appendSlice("Expected ';'") catch return .{ .err = .{ .allocation_failed = void{} } };

                return .{ .err = .{ .invalid_input = .{ .message = message } } };
            }

            const should_break = switch (input_[0]) {
                .punct => |x| mem.eql(u8, x.value, ";"),
                else => false,
            };

            input_ = input_[1..];

            if (should_break) {
                break;
            }
        }
    }

    return .{ .ok = .{ input_, self } };
}

pub fn format(self: Self, writer: fs.File.Writer) FormatError!void {
    for (self.binds.items) |bind| {
        try bind.format(writer);
    }
}
