const std = @import("std");
const allocator = std.testing.allocator;
const Zmd = @import("../zmd/Zmd.zig");
const Node = @import("../zmd/Node.zig");
const expectEqualStrings = std.testing.expectEqualStrings;

test "parse markdown and translate to HTML" {
    const html =
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
    ;

    const md =
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
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse content without trailing linebreak before eof" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
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

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse paragraph leading with a token" {
    const html =
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
    ;

    const md =
        \\# Header
        \\
        \\**bold** text at the start of a paragraph
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse indented list" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li>foo</li><li>bar</li><li>baz</li></ul></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\  * foo
        \\  * bar
        \\  * baz
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse underscores in code element" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><ul><li><span style="font-family: Monospace">foo_bar</span></li><li><span style="font-family: Monospace">baz_qux</span></li><li><span style="font-family: Monospace">quux_corge</span></li></ul></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\* `foo_bar`
        \\* `baz_qux`
        \\* `quux_corge`
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse parentheses in paragraph" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>
        \\<p>some text (with parentheses) in a paragraph</p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\some text (with parentheses) in a paragraph
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse underscore in link" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>
        \\<p>a <i>link</i> to <a href="https://en.wikipedia.org/wiki/Here_document">here_doc</a> with <i>italics</i> and <b>bold</b></p>
        \\</main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\a _link_ to [here_doc](https://en.wikipedia.org/wiki/Here_document) with _italics_ and **bold**
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse underscores in block" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><pre class="language-zig" style="font-family: Monospace;"><code>if (foo_bar_baz) return true;</code></pre></main>
        \\</body>
        \\</html>
        \\
    ;

    const md =
        \\```zig
        \\if (foo_bar_baz) return true;
        \\```
    ;

    const parsed = try Zmd.parse(allocator, md, .{});
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}

test "parse repeated whitespace" {
    // Used to be really slow
    const parsed = try Zmd.parse(allocator, " " ** 40_000, .{});
    allocator.free(parsed);
}

fn testFunc(alloc: std.mem.Allocator, node: Node) ![]const u8 {
    return std.fmt.allocPrint(alloc, "<h0>{s}</h0>", .{node.content});
}

test "custom handler func" {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main><h0>Hello</h0></main>
        \\</body>
        \\</html>
        \\
    ;

    const md = "# Hello";

    const parsed = try Zmd.parse(allocator, md, .{ .h1 = testFunc });
    defer allocator.free(parsed);
    try expectEqualStrings(html, parsed);
}
