const std = @import("std");

const Zmd = @import("zmd/Zmd.zig");
const fragments = @import("zmd/html.zig").DefaultFragments;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var zmd = Zmd.init(allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\# Header
        \\## Sub-header
        \\### Sub-sub-header
        \\
        \\some text in **bold** and _italic_
        \\
        \\a paragraph
        \\
        \\```
        \\some code
        \\some more code in the same block
        \\and yet more code
        \\```
        \\some more text with a `code` fragment
    );

    const html = try zmd.toHtml(fragments);
    // defer std.testing.allocator.free(html);

    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(html);
}
