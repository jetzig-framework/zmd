const std = @import("std");
const Writer = std.Io.Writer;

const Config = @This();

root: Tag = .{
    .opening =
    \\<!DOCTYPE html>
    \\<html>
    \\<head>
    \\  <meta charset="utf8">
    \\</head>
    \\<body>
    \\<main>
    \\
    ,
    .closing =
    \\</main>
    \\</body>
    \\</html>
    \\
    ,
},
block: Tag = .{
    .opening =
    \\<pre style="font-family: Monospace;" class="language-{[language]s}">
    \\<code>
    \\
    ,
    .closing =
    \\
    \\</code>
    \\</pre>
    \\
    ,
},
link: Tag = .{
    .opening =
    \\<a href="{[href]s}">
    ,
    .closing = "</a>",
},
image: Tag = .{
    .opening =
    \\<img src="{[href]s}" title="
    ,
    .closing =
    \\">
    ,
},
h1: Tag = .{ .opening = "<h1>", .closing = "</h1>\n" },
h2: Tag = .{ .opening = "<h2>", .closing = "</h2>\n" },
h3: Tag = .{ .opening = "<h3>", .closing = "</h3>\n" },
h4: Tag = .{ .opening = "<h4>", .closing = "</h4>\n" },
h5: Tag = .{ .opening = "<h5>", .closing = "</h5>\n" },
h6: Tag = .{ .opening = "<h6>", .closing = "</h6>\n" },
bold: Tag = .{ .opening = "<b>", .closing = "</b>" },
italic: Tag = .{ .opening = "<i>", .closing = "</i>" },
unordered_list: Tag = .{ .opening = "<ul>\n", .closing = "</ul>\n" },
ordered_list: Tag = .{ .opening = "<ol>\n", .closing = "</ol>\n" },
list_item: Tag = .{ .opening = "  <li>", .closing = "</li>\n" },
code: Tag = .{
    .opening =
    \\<span style="font-family: Monospace;">
    ,
    .closing = "</span>",
},
paragraph: Tag = .{ .opening = "<p>", .closing = "</p>\n" },
text: Tag = .{ .opening = "", .closing = "" },
ref: Tag = .handlebars_ref,

pub const Tag = struct {
    opening: []const u8,
    closing: []const u8,

    pub const jinja_ref: Tag = .{ .opening = "{%", .closing = "%}" };
    pub const handlebars_ref: Tag = .{ .opening = "{{", .closing = "}}" };
};

pub fn write(self: Config, field: Field, writer: *Writer, node: Node) ![]const u8 {
    const tag: Tag = switch (field) {
        .root => self.root,
        .block => self.block,
        .link => self.link,
        .image => self.image,
        .h1 => self.h1,
        .h2 => self.h2,
        .h3 => self.h3,
        .h4 => self.h4,
        .h5 => self.h5,
        .h6 => self.h6,
        .unordered_list => self.unordered_list,
        .ordered_list => self.ordered_list,
        .list_item => self.list_item,
        .bold => self.bold,
        .italic => self.italic,
        .code => self.code,
        .text => self.text,
        .paragraph => self.paragraph,
        .ref => self.ref,
    };
    switch (field) {
        .block => try writeTag(writer, tag.opening, "{[language]s}", node.language orelse ""),
        .link, .image => try writeTag(writer, tag.opening, "{[href]s}", node.href orelse ""),
        else => try writer.writeAll(tag.opening),
    }
    return tag.closing;
}

fn writeTag(writer: *Writer, opening: []const u8, placeholder: []const u8, value: []const u8) !void {
    const index = std.mem.indexOf(u8, opening, placeholder) orelse {
        try writer.writeAll(opening);
        return;
    };
    try writer.writeAll(opening[0..index]);
    try writer.writeAll(value);
    try writer.writeAll(opening[index + placeholder.len ..]);
}

pub const Node = struct {
    language: ?[]const u8 = null,
    href: ?[]const u8 = null,
};

pub const Field = enum {
    root,
    block,
    link,
    image,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    unordered_list,
    ordered_list,
    list_item,
    bold,
    italic,
    code,
    text,
    paragraph,
    ref,
};
