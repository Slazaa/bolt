const std = @import("std");

const mem = std.mem;

const parser = @import("../parser.zig");

const Result = parser.Result;

pub fn tag(pattern: []const u8) *const fn (input: []const u8) Result([]const u8) {
    return struct {
        pub fn f(input: []const u8) Result([]const u8) {
            if (!mem.eql(u8, pattern, input[0..pattern.len])) {
                return .{ .err = .invalid_input };
            }

            return .{ .ok = .{ input[pattern.len..], input[0..pattern.len] } };
        }
    }.f;
}
