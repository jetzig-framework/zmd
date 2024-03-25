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
        \\<main><b>bold</b></main>
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
        \\<main><i>italic</i></main>
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
        \\<main><span style="font-family: Monospace">code</span></main>
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
        \\<main><img src="https://example.com/image.png" title="image title" /></main>
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
        \\<main><a href="https://example.com/">link title</a></main>
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

test "ordered list" {
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
