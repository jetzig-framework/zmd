const std = @import("std");

const Zmd = @import("zmd/Zmd.zig");
const fragments = @import("zmd/html.zig").DefaultFragments;

test {
    std.testing.refAllDeclsRecursive(@This());
}

test "parse markdown and translate to HTML" {
    var zmd = Zmd.init(std.testing.allocator);
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
        \\```
        \\some more text with a `code` fragment
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html><html><body><div><h1> Header</h1>
        \\<h2> Sub-header</h2>
        \\<h3> Sub-sub-header</h3>
        \\<p>some text in <b>bold</b>
        \\ and <i>italic</i>
        \\</p><p>a paragraph</p><pre style="font-family: Monospace">some code
        \\</pre>
        \\some more text with a <span style="font-family: Monospace">code</span>
        \\ fragment</div></body></html>
        \\
    , html);
}
