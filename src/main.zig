const std = @import("std");

const debug = std.debug;
const heap = std.heap;
const io = std.io;

const expr = @import("expr.zig");

pub fn main() !void {
    const input =
        \\51
    ;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var ast = switch (expr.File.parse(allocator, input)) {
        .ok => |x| x[1],
        .err => return error.ASTError,
    };

    defer ast.deinit();

    const stdout = io.getStdOut();
    const stdout_writer = stdout.writer();

    try ast.format(allocator, stdout_writer, 0);
}
