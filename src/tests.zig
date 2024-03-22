const std = @import("std");

const Zmd = @import("zmd/Zmd.zig");

test "parse header" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\## Header
        \\### Sub-header
        \\## H2
    );

    var it = zmd.walk();
    while (it.next()) |node| {
        try std.testing.expectEqualStrings(node.content, "Header");
        return;
    }
    try std.testing.expect(false);
}
