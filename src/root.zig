const std = @import("std");

pub const Zmd = @import("zmd/Zmd.zig");

test {
    _ = @import("tests.zig");
    std.testing.refAllDeclsRecursive(@This());
}
