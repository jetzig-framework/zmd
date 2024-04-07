const std = @import("std");

const Zmd = @import("../zmd/Zmd.zig");
const fragments = @import("../zmd/html.zig").DefaultFragments;

test "h1" {
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

test "h2" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\## Header
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h2>Header</h2>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "h3" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\### Header
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h3>Header</h3>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "h4" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\#### Header
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h4>Header</h4>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "h5" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\##### Header
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h5>Header</h5>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "h6" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\###### Header
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h6>Header</h6>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "bold (dangling)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\**bold**
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><p><b>bold</b></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "bold (embedded)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\some **bold** text
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>some <b>bold</b> text</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "italic (dangling)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\_italic_
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><p><i>italic</i></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "italic (embedded)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\some _italic_ text
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>some <i>italic</i> text</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "code (dangling)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\`code`
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><p><span style="font-family: Monospace">code</span></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "code (embedded)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\some `code` text
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>some <span style="font-family: Monospace">code</span> text</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "block" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\```zig
        \\if (1 < 10) {
        \\   return "1 is less than 10";
        \\}
        \\```
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><pre class="language-zig" style="font-family: Monospace;"><code>if (1 &lt; 10) {
        \\   return "1 is less than 10";
        \\}</code></pre></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "image" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\![image title](https://example.com/image.png)
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><p><img src="https://example.com/image.png" title="image title" /></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "link" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\[link title](https://example.com/)
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><p><a href="https://example.com/">link title</a></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "paragraph" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\# a title
        \\
        \\a paragraph
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h1>a title</h1>
        \\<p>a paragraph</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "unordered list (+)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\+ list item 1
        \\+ list item 2
        \\+ list item 3
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li>list item 1</li><li>list item 2</li><li>list item 3</li></ul></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "unordered list (-)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\- list item 1
        \\- list item 2
        \\- list item 3
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li>list item 1</li><li>list item 2</li><li>list item 3</li></ul></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "unordered list (*)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\* list item 1
        \\* list item 2
        \\* list item 3
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li>list item 1</li><li>list item 2</li><li>list item 3</li></ul></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "ordered list (1., 1., 1.)" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\1. list item 1
        \\1. list item 2
        \\1. list item 3
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ol><li>list item 1</li><li>list item 2</li><li>list item 3</li></ol></main>
        \\</body>
        \\</html>
        \\
    , html);
}

test "list with embedded elements" {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\* list item with [my link](https://www.example.com/)
        \\* list item with ![my image](https://www.example.com/image.png)
        \\* list item with **bold** and _italic_ text
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings(
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li>list item with <a href="https://www.example.com/">my link</a></li><li>list item with <img src="https://www.example.com/image.png" title="my image" /></li><li>list item with <b>bold</b> and <i>italic</i> text</li></ul></main>
        \\</body>
        \\</html>
        \\
    , html);
}
