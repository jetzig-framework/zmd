const std = @import("std");
const zmd = @import("zmd.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const markdown =
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
    ;

    const stdout: std.fs.File = .stdout();
    const writer = stdout.writer(.{});
    try zmd.parseW(allocator, &writer.interface, markdown, .{});
}
