const std = @import("std");
const allocator = std.testing.allocator;
const zmd = @import("../root.zig");
const expectEqualStrings = std.testing.expectEqualStrings;

test "h1" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<h1>Header</h1>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\# Header
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<h2>Header</h2>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\## Header
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<h3>Header</h3>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\### Header
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<h4>Header</h4>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;
    const md =
        \\#### Header
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<h5>Header</h5>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\##### Header
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<h6>Header</h6>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\###### Header
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "italic with asterisks (dangling)" {
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
        \\*italic*
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "italic with asterisks (embedded)" {
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
        \\some *italic* text
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<p><span style="font-family: Monospace;">code</span></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\`code`
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<p>some <span style="font-family: Monospace;">code</span> text</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\some `code` text
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<pre style="font-family: Monospace;" class="language-zig">
        \\<code>
        \\if (1 &lt; 10) {
        \\   return "1 is less than 10";
        \\}
        \\</code>
        \\</pre>
        \\</main>
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<p><img src="https://example.com/image.png" title="image title"></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\![image title](https://example.com/image.png)
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "dangling brackets (no href)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p>index [0] of array</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\index [0] of array
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "passthrough ref ({{ ... }})" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p>value is {{ $.user_name[0] < limit }} today</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\value is {{ $.user_name[0] < limit }} today
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "link with passthrough refs in title and href" {
    // A link whose title and href are `{{ ... }}` refs must still parse as a link, with the refs
    // passed through verbatim for a downstream consumer to resolve.
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><a href="{{$.url}}">{{$.title}}</a></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\[{{$.title}}]({{$.url}})
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "nested image inside link title" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<p><a href="https://example.com/"><img src="https://example.com/i.png" title="alt"></a></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\[![alt](https://example.com/i.png)](https://example.com/)
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<h1>a title</h1>
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

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<ul>
        \\  <li>list item 1</li>
        \\  <li>list item 2</li>
        \\  <li>list item 3</li>
        \\</ul>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\+ list item 1
        \\+ list item 2
        \\+ list item 3
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<ul>
        \\  <li>list item 1</li>
        \\  <li>list item 2</li>
        \\  <li>list item 3</li>
        \\</ul>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\- list item 1
        \\- list item 2
        \\- list item 3
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<ul>
        \\  <li>list item 1</li>
        \\  <li>list item 2</li>
        \\  <li>list item 3</li>
        \\</ul>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\* list item 1
        \\* list item 2
        \\* list item 3
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<ol>
        \\  <li>list item 1</li>
        \\  <li>list item 2</li>
        \\  <li>list item 3</li>
        \\</ol>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\1. list item 1
        \\1. list item 2
        \\1. list item 3
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "ordered list (1., 2., 3.)" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<ol>
        \\  <li>list item 1</li>
        \\  <li>list item 2</li>
        \\  <li>list item 3</li>
        \\</ol>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\1. list item 1
        \\2. list item 2
        \\3. list item 3
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
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
        \\<main>
        \\<ul>
        \\  <li>list item with <a href="https://www.example.com/">my link</a></li>
        \\  <li>list item with <img src="https://www.example.com/image.png" title="my image"></li>
        \\  <li>list item with <b>bold</b> and <i>italic</i> text</li>
        \\</ul>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\* list item with [my link](https://www.example.com/)
        \\* list item with ![my image](https://www.example.com/image.png)
        \\* list item with **bold** and _italic_ text
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "nested mixed ordered and unordered lists" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\<ol>
        \\  <li>first</li>
        \\  <li>second
        \\    <ul>
        \\      <li>bullet a</li>
        \\      <li>bullet b</li>
        \\    </ul>
        \\  </li>
        \\  <li>third</li>
        \\</ol>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;
    const md =
        \\1. first
        \\2. second
        \\  * bullet a
        \\  * bullet b
        \\3. third
    ;

    const parsed = try zmd.parseAlloc(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}
