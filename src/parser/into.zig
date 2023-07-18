const ParserResult = @import("../parser.zig").Result;

pub fn into(
    comptime I: type,
    comptime O: type,
    parser: *const fn (input: []const u8) ParserResult(I),
    constructor: *const fn (item: anytype) ParserResult(O),
) *const fn (input: []const u8) ParserResult(O) {
    return struct {
        pub fn f(input: []const u8) ParserResult(O) {
            const res = switch (parser(input)) {
                .ok => |x| x,
                .err => |e| return .{ .err = e },
            };

            return .{ .ok = .{ res[0], constructor(res[1]) } };
        }
    }.f;
}
