const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub const expr = @import("ast/expr.zig");

const File = expr.File;

pub const InvalidInputError = struct {
    const Self = @This();

    message: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, message_slice: []const u8) !Self {
        var message = std.ArrayList(u8).init(allocator);
        errdefer message.deinit();

        try message.appendSlice(message_slice);

        return .{
            .message = message,
        };
    }

    pub fn deinit(self: Self) void {
        self.message.deinit();
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        try fmt.print(writer, "Invalid input: {s}\n", .{
            self.message.items,
        });
    }
};

pub const InputLeftError = struct {
    const Self = @This();

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        _ = self;
        try fmt.print(writer, "Input left\n", .{});
    }
};

pub const Error = union(enum) {
    const Self = @This();

    invalid_input: InvalidInputError,
    input_left: InputLeftError,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            InvalidInputError => .{ .invalid_input = item },
            InputLeftError => .{ .input_left = item },
            else => @panic("Expected Expr, found " ++ @typeName(T)),
        };
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .invalid_input => |x| x.deinit(),
            else => {},
        }
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(writer),
        }
    }
};

pub fn Result(comptime T: type) type {
    return union(enum) {
        ok: T,
        err: Error,
    };
}

pub fn parse(allocator: mem.Allocator, input: []const Token) !Result(File) {
    var input_ = input;

    const expr_ = switch (try File.parse(allocator, &input_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    if (input_.len != 0) {
        return .{ .err = .input_left };
    }

    return .{ .ok = expr_ };
}
