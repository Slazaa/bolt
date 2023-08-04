const Self = @This();

line: usize,
column: usize,
index: usize,

pub fn default() Self {
    return Self{
        .line = 1,
        .column = 1,
        .index = 0,
    };
}
