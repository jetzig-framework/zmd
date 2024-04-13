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
        \\
        \\<p>some text in <b>bold</b> and <i>italic</i></p>
        \\
        \\<p>a paragraph</p>
        \\
        \\<p>a link: <a href="https://ziglang.org/">my link</a></p>
        \\
        \\<p>an image: <img src="https://www.jetzig.dev/jetzig.png" title="jetzig logo" /></p>
        \\<pre class="language-zig" style="font-family: Monospace;"><code>if (1 &lt; 10) {
        \\    std.debug.print("1 is &lt; 10 !");
        \\}</code></pre>
        \\<p>some more text with a <span style="font-family: Monospace">code</span> fragment</p>
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

test "parse paragraph leading with a token" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\# Header
        \\
        \\**bold** text at the start of a paragraph
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h1>Header</h1>
        \\
        \\<p><b>bold</b> text at the start of a paragraph</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "parse indented list" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\  * foo
        \\  * bar
        \\  * baz
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li>foo</li><li>bar</li><li>baz</li></ul></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "parse underscores in code element" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\* `foo_bar`
        \\* `baz_qux`
        \\* `quux_corge`
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li><span style="font-family: Monospace">foo_bar</span></li><li><span style="font-family: Monospace">baz_qux</span></li><li><span style="font-family: Monospace">quux_corge</span></li></ul></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "parse parentheses in paragraph" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\some text (with parentheses) in a paragraph
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>
        \\<p>some text (with parentheses) in a paragraph</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "parse underscore in link" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\a _link_ to [here_doc](https://en.wikipedia.org/wiki/Here_document) with _italics_ and **bold**
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>
        \\<p>a <i>link</i> to <a href="https://en.wikipedia.org/wiki/Here_document">here_doc</a> with <i>italics</i> and <b>bold</b></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "parse underscores in block" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\```zig
        \\if (foo_bar_baz) return true;
        \\```
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><pre class="language-zig" style="font-family: Monospace;"><code>if (foo_bar_baz) return true;</code></pre></main>
        \\</body>
        \\</html>
        \\
    , html);
}
