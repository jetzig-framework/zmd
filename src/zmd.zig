const std = @import("std");

pub const Zmd = @import("zmd/Zmd.zig");
pub const html = @import("zmd/html.zig");

test {
    _ = @import("tests.zig");
    std.testing.refAllDeclsRecursive(@This());
}
