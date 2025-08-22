const std = @import("std");
const allocator = std.testing.allocator;
const zmd = @import("../zmd.zig");
const expectEqualStrings = std.testing.expectEqualStrings;

test "h1" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h1>Header</h1>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\# Header
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "h2" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h2>Header</h2>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\## Header
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "h3" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h3>Header</h3>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\### Header
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "h4" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h4>Header</h4>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;
    const md =
        \\#### Header
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "h5" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h5>Header</h5>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\##### Header
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "h6" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h6>Header</h6>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\###### Header
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "bold (dangling)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><b>bold</b></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\**bold**
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "bold (embedded)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p>some <b>bold</b> text</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\some **bold** text
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "italic (dangling)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><i>italic</i></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\_italic_
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "italic (embedded)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p>some <i>italic</i> text</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\some _italic_ text
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "code (dangling)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><span style="font-family: Monospace">code</span></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\`code`
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "code (embedded)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p>some <span style="font-family: Monospace">code</span> text</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\some `code` text
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "block" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><pre class="language-zig" style="font-family: Monospace;"><code>if (1 &lt; 10) {
        \\   return "1 is less than 10";
        \\}</code></pre></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\```zig
        \\if (1 < 10) {
        \\   return "1 is less than 10";
        \\}
        \\```
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "image" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><img src="https://example.com/image.png" title="image title" /></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\![image title](https://example.com/image.png)
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "link" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><a href="https://example.com/">link title</a></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\[link title](https://example.com/)
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "paragraph" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><h1>a title</h1>
        \\
        \\<p>a paragraph</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\# a title
        \\
        \\a paragraph
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "unordered list (+)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><ul><li>list item 1</li><li>list item 2</li><li>list item 3</li></ul></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\+ list item 1
        \\+ list item 2
        \\+ list item 3
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "unordered list (-)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><ul><li>list item 1</li><li>list item 2</li><li>list item 3</li></ul></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\- list item 1
        \\- list item 2
        \\- list item 3
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "unordered list (*)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><ul><li>list item 1</li><li>list item 2</li><li>list item 3</li></ul></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\* list item 1
        \\* list item 2
        \\* list item 3
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "ordered list (1., 1., 1.)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><ol><li>list item 1</li><li>list item 2</li><li>list item 3</li></ol></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\1. list item 1
        \\1. list item 2
        \\1. list item 3
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "list with embedded elements" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main><ul><li>list item with <a href="https://www.example.com/">my link</a></li><li>list item with <img src="https://www.example.com/image.png" title="my image" /></li><li>list item with <b>bold</b> and <i>italic</i> text</li></ul></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\* list item with [my link](https://www.example.com/)
        \\* list item with ![my image](https://www.example.com/image.png)
        \\* list item with **bold** and _italic_ text
    ;

    const parsed = try zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}
