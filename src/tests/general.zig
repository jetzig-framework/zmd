const std = @import("std");

const Zmd = @import("../zmd/Zmd.zig");
const fragments = @import("../zmd/html.zig").DefaultFragments;

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
        \\a link: [my link](https://ziglang.org/)
        \\
        \\an image: ![jetzig logo](https://www.jetzig.dev/jetzig.png)
        \\
        \\```zig
        \\if (1 < 10) {
        \\    std.debug.print("1 is < 10 !");
        \\}
        \\```
        \\some more text with a `code` fragment
        \\
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h1>Header</h1>
        \\<h2>Sub-header</h2>
        \\<h3>Sub-sub-header</h3>
        \\<p>some text in <b>bold</b> and <i>italic</i></p>
        \\<p>a paragraph</p>
        \\<p>a link: <a href="https://ziglang.org/">my link</a></p>
        \\<p>an image: <img src="https://www.jetzig.dev/jetzig.png" title="jetzig logo" /></p>
        \\<pre class="language-zig" style="font-family: Monospace;"><code>if (1 &lt; 10) {
        \\    std.debug.print("1 is &lt; 10 !");
        \\}
        \\</code></pre><p>some more text with a <span style="font-family: Monospace">code</span> fragment</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "parse content without trailing linebreak before eof" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\# Header
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h1>Header</h1>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}
