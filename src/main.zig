const std = @import("std");

const heap = std.heap;
const testing = std.testing;

const expr = @import("expr.zig");

test "parse test" {
    const input =
        \\51
    ;

    var arena = heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var ast = switch (expr.File.parse(allocator, input)) {
        .ok => |x| x[1],
        .err => return error.ASTError,
    };

    defer ast.deinit();
}
