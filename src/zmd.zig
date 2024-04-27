const std = @import("std");

pub const zmd = @This();

pub const Zmd = @import("zmd/Zmd.zig");
pub const Node = @import("zmd/Node.zig");
pub const Ast = @import("zmd/Ast.zig");
pub const tokens = @import("zmd/tokens.zig");
pub const html = @import("zmd/html.zig");
pub const getFormatter = Node.getFormatter;

test {
    _ = @import("tests.zig");
}
