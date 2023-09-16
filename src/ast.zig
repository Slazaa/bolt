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

pub const ErrorInfo = union(enum) {
    const Self = @This();

    invalid_input: InvalidInputError,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            InvalidInputError => .{ .invalid_input = item },
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

pub fn parse(
    allocator: mem.Allocator,
    input: []const Token,
    err_info: ?*ErrorInfo,
) !File {
    var input_ = input;

    const expr_ = b: {
        var err_info_: ErrorInfo = undefined;

        break :b File.parse(
            allocator,
            &input_,
            if (err_info) |_| &err_info_ else null,
        ) catch |err| {
            if (err_info) |info| info.* = err_info_;
            return err;
        };
    };

    if (input_.len != 0) {
        return error.InputLeft;
    }

    return expr_;
}
