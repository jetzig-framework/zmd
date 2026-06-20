const std = @import("std");
const zmd = @import("root.zig");

pub fn main(init: std.process.Init) !void {
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
        \\- list item
        \\  1. ordered item
    ;
    const stdout: std.Io.File = .stdout();
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(init.io, &buf);
    try zmd.parseSlice(markdown, &writer.interface, .{});
}
