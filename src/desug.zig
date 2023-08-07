const std = @import("std");

const mem = std.mem;

const ast_ = @import("ast.zig");

const AstFile = ast_.expr.File;

const expr = @import("desug_ast/expr.zig");

const File = expr.File;

pub fn desug(allocator: mem.Allocator, ast: AstFile) File {
    return File.desug(allocator, ast);
}
