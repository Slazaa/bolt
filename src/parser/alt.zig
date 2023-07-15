const parser = @import("../parser.zig");

const Result = parser.Result;

pub fn alt(
    comptime T: type,
    comptime parsers: []const *const fn (input: []const u8) Result(T),
) *const fn (input: []const u8) Result(T) {
    return struct {
        pub fn f(input: []const u8) Result(T) {
            for (parsers) |p| {
                switch (p(input)) {
                    .ok => |x| return .{ .ok = x },
                    .err => {},
                }
            }

            return .{ .err = .invalid_input };
        }
    }.f;
}
