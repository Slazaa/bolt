const std = @import("std");

const mem = std.mem;

const parser = @import("../parser.zig");

const Result = parser.Result;

const Expr = @import("../expr.zig").Expr;

const Self = @This();

exprs: std.ArrayList(Expr),

pub fn init(allocator: mem.Allocator) Self {
    return Self{
        .exprs = std.ArrayList(Expr).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.exprs.deinit();
}

pub fn parse(allocator: mem.Allocator, input: []const u8) Result(Self) {
    var self = Self.init(allocator);
    var new_input = input;

    while (new_input.len != 0) {
        const res = switch (Expr.parse(allocator, new_input)) {
            .ok => |x| x,
            .err => |e| return .{ .err = e },
        };

        new_input = res[0];

        self.exprs.append(res[1]) catch {
            @panic("Could not append to File");
        };
    }

    return .{ .ok = .{ &[_]u8{}, self } };
}
