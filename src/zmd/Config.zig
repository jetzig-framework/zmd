const std = @import("std");
const Node = @import("Node.zig");
const Config = @This();
const Allocator = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;
pub const Fn = *const fn (Allocator, Node) Allocator.Error![]const u8;

root: Fn = defaultRoot,
block: Fn = defaultBlock,
link: Fn = defaultLink,
image: Fn = defaultImage,
h1: Fn = defaultH1,
h2: Fn = defaultH2,
h3: Fn = defaultH3,
h4: Fn = defaultH4,
h5: Fn = defaultH5,
h6: Fn = defaultH6,
bold: Fn = defaultBold,
italic: Fn = defaultItalic,
unordered_list: Fn = defaultUnorderedList,
ordered_list: Fn = defaultOrderedList,
list_item: Fn = defaultListItem,
code: Fn = defaultCode,
paragraph: Fn = defaultParagraph,
text: Fn = defaultText,

pub const default: Config = .{
    .root = defaultRoot,
    .block = defaultBlock,
    .link = defaultLink,
    .image = defaultImage,
    .h1 = defaultH1,
    .h2 = defaultH2,
    .h3 = defaultH3,
    .h4 = defaultH4,
    .h5 = defaultH5,
    .h6 = defaultH6,
    .bold = defaultBold,
    .italic = defaultItalic,
    .unordered_list = defaultUnorderedList,
    .ordered_list = defaultOrderedList,
    .list_item = defaultListItem,
    .code = defaultCode,
    .paragraph = defaultParagraph,
    .text = defaultText,
};

fn defaultRoot(allocator: Allocator, node: Node) ![]const u8 {
    const html =
        \\<!DOCTYPE html>
        \\<html>
        \\<head>
        \\  <meta charset="utf8">
        \\</head>
        \\<body>
        \\<main>
        \\{s}</main>
        \\</body>
        \\</html>
        \\
    ;
    return allocPrint(allocator, html, .{node.content});
}

fn defaultBlock(allocator: Allocator, node: Node) ![]const u8 {
    const style = "font-family: Monospace;";
    return if (node.meta) |meta|
        allocPrint(allocator,
            \\<pre class="language-{s}" style="{s}">
            \\<code>
            \\{s}
            \\</code>
            \\</pre>
            \\
        , .{ meta, style, node.content })
    else
        allocPrint(allocator,
            \\<pre style="{s}">
            \\<code>
            \\{s}
            \\</code>
            \\</pre>
            \\
        , .{ style, node.content });
}

fn defaultLink(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<a href="{s}">{s}</a>
    , .{ node.href.?, node.title.? });
}

fn defaultImage(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<img src="{s}" title="{s}">
    , .{ node.href.?, node.title.? });
}

fn defaultH1(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<h1>{s}</h1>
        \\
    , .{node.content});
}

fn defaultH2(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<h2>{s}</h2>
        \\
    , .{node.content});
}

fn defaultH3(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<h3>{s}</h3>
        \\
    , .{node.content});
}

pub fn defaultH4(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<h4>{s}</h4>
        \\
    , .{node.content});
}

fn defaultH5(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<h5>{s}</h5>
        \\
    , .{node.content});
}

fn defaultH6(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<h6>{s}</h6>
        \\
    , .{node.content});
}

fn defaultBold(allocator: Allocator, node: Node) ![]const u8 {
    return wrap(allocator, node.content, "b");
}

fn defaultItalic(allocator: Allocator, node: Node) ![]const u8 {
    return wrap(allocator, node.content, "i");
}

fn defaultUnorderedList(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<ul>
        \\{s}</ul>
        \\
    , .{node.content});
}

fn defaultOrderedList(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<ol>
        \\{s}</ol>
        \\
    , .{node.content});
}

fn defaultListItem(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\  <li>{s}</li>
        \\
    , .{node.content});
}

fn defaultCode(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<span style="font-family: Monospace;">{s}</span>
    , .{node.content});
}

fn defaultParagraph(allocator: Allocator, node: Node) ![]const u8 {
    return allocPrint(allocator,
        \\<p>{s}</p>
        \\
    , .{node.content});
}

fn defaultText(allocator: Allocator, node: Node) ![]const u8 {
    _ = allocator;
    return node.content;
}

fn wrap(allocator: Allocator, content: []const u8, string: []const u8) ![]const u8 {
    return allocPrint(
        allocator,
        "<{[tag]s}>{[content]s}</{[tag]s}>",
        .{ .tag = string, .content = content },
    );
}
