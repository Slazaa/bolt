const std = @import("std");

const fs = std.fs;
const io = std.io;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("fmt.zig");

const lexer = @import("lexer.zig");

const Token = lexer.Token;

pub const Bind = @import("expr/Bind.zig");
pub const File = @import("expr/File.zig");
pub const FnCall = @import("expr/FnCall.zig");
pub const Ident = @import("expr/Ident.zig");
pub const Literal = @import("expr/literal.zig").Literal;
pub const NumLit = @import("expr/literal.zig").NumLit;

pub const InvalidInputError = struct {
    const Self = @This();

    message: std.ArrayList(u8),

    pub fn init(allocator: mem.Allocator, message_slice: []const u8) Self {
        var message = std.ArrayList(u8).init(allocator);
        message.appendSlice(message_slice) catch @panic("Allocation failed");

        return .{
            .message = message,
        };
    }

    pub fn deinit(self: Self) void {
        self.message.deinit();
    }

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        try fmt.print(writer, "Invalid input: {s}", .{
            self.message.items,
        });
    }
};

pub const InputLeftError = struct {
    const Self = @This();

    pub fn format(self: Self, writer: Writer) fmt.Error!void {
        _ = self;
        try fmt.print(writer, "Input left", .{});
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
            else => @compileError("Expected expr, found " ++ @typeName(T)),
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

pub const Expr = union(enum) {
    const Self = @This();

    file: File,
    fn_call: FnCall,
    ident: Ident,
    literal: Literal,

    pub fn from(item: anytype) Self {
        const T = @TypeOf(item);

        return switch (T) {
            File => .{ .file = item },
            FnCall => .{ .fn_call = item },
            Ident => .{ .ident = item },
            Literal => .{ .literal = item },
            else => @compileError("Expected Expr, found " ++ @typeName(T)),
        };
    }

    pub fn deinit(self: Self) void {
        switch (self) {
            .file => |x| x.deinit(),
            else => {},
        }
    }

    pub fn parse(allocator: mem.Allocator, input: *[]const Token) Result(Expr) {
        const parsers = .{
            Literal.parse,
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
        writer: fs.File.Writer,
        depth: usize,
    ) fmt.Error!void {
        switch (self) {
            inline else => |x| try x.format(allocator, writer, depth),
        }
    }
};

pub fn parse(allocator: mem.Allocator, input: []const Token) Result(File) {
    var input_ = input;

    const expr = switch (File.parse(allocator, &input_)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    if (input_.len != 0) {
        return .{ .err = .input_left };
    }

    return .{ .ok = expr };
}
