const std = @import("std");

const fs = std.fs;
const mem = std.mem;

const Writer = fs.File.Writer;

const fmt = @import("../../fmt.zig");

const ast = @import("../../ast.zig");
const lexer = @import("../../lexer.zig");

const IdentTok = lexer.Ident;

const AstIdent = ast.expr.Ident;

const Self = @This();

value: IdentTok,

pub fn desug(ident: AstIdent) Self {
    return .{
        .value = ident.value,
    };
}

pub fn format(
    self: Self,
    allocator: mem.Allocator,
    writer: Writer,
    depth: usize,
) fmt.Error!void {
    var depth_tabs = std.ArrayList(u8).init(allocator);
    defer depth_tabs.deinit();

    try fmt.addDepth(&depth_tabs, depth);

    try fmt.print(writer, "{s}Ident {{\n", .{
        depth_tabs.items,
    });

    try fmt.print(writer, "{s}    value: {s}\n", .{
        depth_tabs.items,
        self.value.value,
    });

    try fmt.print(writer, "{s}}}\n", .{depth_tabs.items});
}
