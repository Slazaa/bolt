const std = @import("std");

const ascii = std.ascii;
const mem = std.mem;
const testing = std.testing;

const parser = @import("../parser.zig");

const ParserResult = parser.Result;

pub fn digit0(input: []const u8) ParserResult([]const u8, []const u8) {
    var i: usize = 0;

    while (i < input.len) {
        if (!ascii.isDigit(input[i])) {
            return .{ .ok = .{ input[i..], input[0..i] } };
        }

        i += 1;
    }

    return .{ .ok = .{ &[_]u8{}, input } };
}

pub fn digit1(input: []const u8) ParserResult([]const u8, []const u8) {
    if (input.len == 0 or !ascii.isDigit(input[0])) {
        return .{ .err = .invalid_input };
    }

    return digit0(input);
}
