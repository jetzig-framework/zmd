const std = @import("std");
const Zmd = @import("zmd/Zmd.zig");

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

    const html = try Zmd.parse(allocator, markdown, .{});
    defer allocator.free(html);

    const stdout = std.fs.File.stdout();
    try stdout.writeAll(html);
}
