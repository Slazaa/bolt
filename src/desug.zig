const std = @import("std");

const mem = std.mem;

const ast_ = @import("ast.zig");

const AstFile = ast_.expr.File;

pub const expr = @import("desug/expr.zig");

const File = expr.File;

pub fn desug(allocator: mem.Allocator, ast: AstFile) !File {
    return try File.desug(allocator, ast);
}
