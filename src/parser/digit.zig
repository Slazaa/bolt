const std = @import("std");

const ascii = std.ascii;
const mem = std.mem;
const testing = std.testing;

const parser = @import("../parser.zig");

const Result = parser.Result;

pub fn digit0(input: []const u8) Result([]const u8) {
    var i: usize = 0;

    while (i < input.len) {
        if (!ascii.isDigit(input[i])) {
            return .{ .ok = .{ input[i..], input[0..i] } };
        }

        i += 1;
    }

    return .{ .ok = .{ &[_]u8{}, input } };
}

pub fn digit1(input: []const u8) Result([]const u8) {
    if (input.len == 0 or !ascii.isDigit(input[0])) {
        return .{ .err = .invalid_input };
    }

    return digit0(input);
}

fn testEquals(first: Result([]const u8), second: Result([]const u8)) bool {
    switch (first) {
        .ok => {
            if (second != .ok) return false;
            return mem.eql(u8, first.ok[0], second.ok[0]) and mem.eql(u8, first.ok[1], second.ok[1]);
        },
        .err => {
            if (second != .err) return false;
            return first.err == second.err;
        },
    }
}

test "digit0" {
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "", "12" } }, digit0("12")));
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "a", "12" } }, digit0("12a")));
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "a3", "12" } }, digit0("12a3")));
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "a12", "" } }, digit0("a12")));
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "a12b", "" } }, digit0("a12b")));
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "a1b2c", "" } }, digit0("a1b2c")));
    try testing.expect(testEquals(Result([]const u8){ .ok = .{ "", "" } }, digit0("")));
}

// test "digit1" {
//     try testing.expectEqual(Result([]const u8){ .ok = .{ "", "12" } }, digit1("12"));
//     try testing.expectEqual(Result([]const u8){ .ok = .{ "a", "12" } }, digit1("12a"));
//     try testing.expectEqual(Result([]const u8){ .ok = .{ "a3", "12" } }, digit1("12a3"));
//     try testing.expectEqual(Result([]const u8){ .err = .invalid_input }, digit1("a12"));
//     try testing.expectEqual(Result([]const u8){ .err = .invalid_input }, digit1("a12b"));
//     try testing.expectEqual(Result([]const u8){ .err = .invalid_input }, digit1("a1b2c"));
//     try testing.expectEqual(Result([]const u8){ .err = .invalid_input }, digit1(""));
// }
