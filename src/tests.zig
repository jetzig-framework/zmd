const std = @import("std");

test {
    _ = @import("tests/general.zig");
    _ = @import("tests/elements.zig");
    std.testing.refAllDeclsRecursive(@This());
}
