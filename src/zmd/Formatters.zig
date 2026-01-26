const std = @import("std");
const Node = @import("Node.zig");
const Writer = std.Io.Writer;
const Formatters = @This();
pub const Handler = fn (*Writer, Node) Writer.Error![]const u8;

root: Handler = Default.root,
block: Handler = Default.block,
link: Handler = Default.link,
image: Handler = Default.image,
h1: Handler = Default.h1,
h2: Handler = Default.h2,
h3: Handler = Default.h3,
h4: Handler = Default.h4,
h5: Handler = Default.h5,
h6: Handler = Default.h6,
bold: Handler = Default.bold,
italic: Handler = Default.italic,
unordered_list: Handler = Default.unordered_list,
ordered_list: Handler = Default.ordered_list,
list_item: Handler = Default.list_item,
code: Handler = Default.code,
paragraph: Handler = Default.paragraph,
default: Handler = Default.default,

const Default = struct {
    pub fn root(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
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

    pub fn block(writer: *Writer, node: Node) Writer.Error![]const u8 {
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

    pub fn link(writer: *Writer, node: Node) Writer.Error![]const u8 {
        try writer.print(
            \\<a href="{s}">{s}</a>
        , .{ node.href.?, node.title.? });
        return "";
    }

    pub fn image(writer: *Writer, node: Node) Writer.Error![]const u8 {
        try writer.print(
            \\<img src="{s}" title="{s}">
        , .{ node.href.?, node.title.? });
        return "";
    }

    pub fn h1(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<h1>");
        return 
        \\</h1>
        \\
        ;
    }

    pub fn h2(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<h2>");
        return 
        \\</h2>
        \\
        ;
    }

    pub fn h3(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<h3>");
        return 
        \\</h3>
        \\
        ;
    }

    pub fn h4(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<h4>");
        return 
        \\</h4>
        \\
        ;
    }

    pub fn h5(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<h5>");
        return 
        \\</h5>
        \\
        ;
    }

    pub fn h6(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<h6>");
        return 
        \\</h6>
        \\
        ;
    }

    pub fn bold(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<b>");
        return "</b>";
    }

    pub fn italic(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<i>");
        return "</i>";
    }

    pub fn unordered_list(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll(
            \\<ul>
            \\
        );
        return 
        \\</ul>
        \\
        ;
    }

    pub fn ordered_list(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll(
            \\<ol>
            \\
        );
        return 
        \\</ol>
        \\
        ;
    }

    pub fn list_item(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("  <li>");
        return 
        \\</li>
        \\
        ;
    }

    pub fn code(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll(
            \\<span style="font-family: Monospace;">
        );

        return "</span>";
    }

    pub fn paragraph(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = node;
        try writer.writeAll("<p>");
        return 
        \\</p>
        \\
        ;
    }

    pub fn default(writer: *Writer, node: Node) Writer.Error![]const u8 {
        _ = writer;
        _ = node;
        return "";
    }
};
