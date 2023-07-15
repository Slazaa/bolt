const parser = @import("../parser.zig");

const Result = parser.Result;

const digit1 = parser.digit1;

const Self = @This();

value: []const u8,

pub fn parse(input: []const u8) Result(Self) {
    const res = switch (digit1(input)) {
        .ok => |x| x,
        .err => |e| return .{ .err = e },
    };

    return .{ .ok = .{ res[0], Self{ .value = res[1] } } };
}

test "NumLit parse" {}
