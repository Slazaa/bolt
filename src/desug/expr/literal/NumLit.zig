const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../../fmt.zig");

const ast = @import("../../../ast.zig");
const lexer = @import("../../../lexer.zig");

const LitTok = lexer.Literal;

const AstNumLit = ast.expr.NumLit;

const Self = @This();

value: LitTok,

pub fn desug(num_lit: AstNumLit) Self {
    return .{
        .value = num_lit.value,
    };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
    depth: usize,
) fmt.Error!void {
    var depth_tags = std.ArrayList(u8).init(allocator);
    defer depth_tags.deinit();

    try fmt.addDepth(&depth_tags, depth);

    try fmt.print(writer, "{s}NumLit {{\n", .{
        depth_tags.items,
    });

    try fmt.print(writer, "{s}    value: {s}\n", .{
        depth_tags.items,
        self.value.value,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tags.items});
}
