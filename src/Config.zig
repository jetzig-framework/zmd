const std = @import("std");
const Node = @import("Parser.zig").Node;
const Config = @This();
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
pub const Fn = *const fn (*Writer, Node) anyerror![]const u8;

root: Fn = Default.root,
block: Fn = Default.block,
link: Fn = Default.link,
image: Fn = Default.image,
h1: Fn = Default.h1,
h2: Fn = Default.h2,
h3: Fn = Default.h3,
h4: Fn = Default.h4,
h5: Fn = Default.h5,
h6: Fn = Default.h6,
bold: Fn = Default.bold,
italic: Fn = Default.italic,
unordered_list: Fn = Default.unorderedList,
ordered_list: Fn = Default.orderedList,
list_item: Fn = Default.listItem,
code: Fn = Default.code,
paragraph: Fn = Default.paragraph,
text: Fn = Default.text,
ref: Fn = Default.ref,

pub fn jinjaRef(writer: *Writer, _: Node) anyerror![]const u8 {
    try writer.writeAll("{%");
    return "%}";
}

pub const default: Config = .{
    .root = Default.root,
    .block = Default.block,
    .link = Default.link,
    .image = Default.image,
    .h1 = Default.h1,
    .h2 = Default.h2,
    .h3 = Default.h3,
    .h4 = Default.h4,
    .h5 = Default.h5,
    .h6 = Default.h6,
    .bold = Default.bold,
    .italic = Default.italic,
    .unordered_list = Default.unorderedList,
    .ordered_list = Default.orderedList,
    .list_item = Default.listItem,
    .code = Default.code,
    .paragraph = Default.paragraph,
    .text = Default.text,
    .ref = Default.ref,
};

const Default = struct {
    pub fn root(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll(
            \\<!DOCTYPE html>
            \\<html>
            \\<head>
            \\  <meta charset="utf8">
            \\</head>
            \\<body>
            \\<main>
            \\
        );
        return
        \\</main>
        \\</body>
        \\</html>
        \\
        ;
    }

    pub fn block(writer: *Writer, node: Node) ![]const u8 {
        try writer.writeAll(
            \\<pre style="font-family: Monospace;"
        );
        if (node.meta) |meta|
            try writer.print(
                \\ class="language-{s}"
            , .{meta});
        try writer.writeAll(
            \\>
            \\<code>
            \\
        );
        return
        \\
        \\</code>
        \\</pre>
        \\
        ;
    }

    pub fn link(writer: *Writer, node: Node) ![]const u8 {
        try writer.print(
            \\<a href="{s}">
        , .{node.href.?});
        return "</a>";
    }

    pub fn image(writer: *Writer, node: Node) ![]const u8 {
        try writer.print(
            \\<img src="{s}" title="
        , .{node.href.?});
        return "\">";
    }

    pub fn h1(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<h1>");
        return
        \\</h1>
        \\
        ;
    }

    pub fn h2(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<h2>");
        return
        \\</h2>
        \\
        ;
    }

    pub fn h3(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<h3>");
        return
        \\</h3>
        \\
        ;
    }

    pub fn h4(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<h4>");
        return
        \\</h4>
        \\
        ;
    }

    pub fn h5(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<h5>");
        return
        \\</h5>
        \\
        ;
    }

    pub fn h6(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<h6>");
        return
        \\</h6>
        \\
        ;
    }

    pub fn bold(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<b>");
        return "</b>";
    }

    pub fn italic(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<i>");
        return "</i>";
    }

    pub fn unorderedList(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll(
            \\<ul>
            \\
        );
        return
        \\</ul>
        \\
        ;
    }

    pub fn orderedList(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll(
            \\<ol>
            \\
        );
        return
        \\</ol>
        \\
        ;
    }

    pub fn listItem(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("  <li>");
        return
        \\</li>
        \\
        ;
    }

    pub fn code(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll(
            \\<span style="font-family: Monospace;">
        );

        return "</span>";
    }

    pub fn paragraph(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("<p>");
        return
        \\</p>
        \\
        ;
    }

    pub fn text(_: *Writer, _: Node) ![]const u8 {
        return "";
    }

    pub fn ref(writer: *Writer, _: Node) ![]const u8 {
        try writer.writeAll("{{");
        return "}}";
    }
};
