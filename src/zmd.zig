const std = @import("std");

const Zmd = @import("zmd/Zmd.zig");
pub const Node = @import("zmd/Node.zig");
pub const Ast = @import("zmd/Ast.zig");
pub const tokens = @import("zmd/tokens.zig");
pub const parse = Zmd.parse;

test {
    _ = @import("tests.zig");
}
