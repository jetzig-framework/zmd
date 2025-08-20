const std = @import("std");
const Fragment = @This();
const tokens = @import("tokens.zig");
const Node = @import("Node.zig");

// test
const NewFragments = .{
    .root = root,
    .block = block,
    .link = link,
    .image = image,
    .h1 = h1,
    .h2 = h2,
    .h3 = h3,
    .h4 = h4,
    .h5 = h5,
    .h6 = h6,
    .bold = bold,
    .italic = italic,
    .ordered_list = ordered_list,
    .unordered_list = unordered_list,
    .list_item = list_item,
    .code = code,
    .paragraph = paragraph,
    .default = default,
};

fn block(allocator: std.mem.Allocator, node: Node) ![]const u8 {
    const style = "font-family: Monospace;";

    return if (node.meta) |meta|
        std.fmt.allocPrint(allocator,
            \\<pre class="language-{s}" style="{s}"><code>{s}</code></pre>
        , .{ meta, style, node.content })
    else
        std.fmt.allocPrint(allocator,
            \\<pre style="{s}"><code>{s}</code></pre>
        , .{ style, node.content });
}

fn link(allocator: std.mem.Allocator, node: Node) ![]const u8 {
    return std.fmt.allocPrint(allocator,
        \\<a href="{s}">{s}</a>
    , .{ node.href.?, node.title.? });
}

fn image(allocator: std.mem.Allocator, node: Node) ![]const u8 {
    return std.fmt.allocPrint(allocator,
        \\<img src="{s}" title="{s}" />
    , .{ node.href.?, node.title.? });
}

fn root(allocator: std.mem.Allocator, node: Node) ![]const u8 {
    return try std.fmt.allocPrint(allocator,
        \\<!DOCTYPE html>
        \\<html>
        \\<body>
        \\<main>{s}</main>
        \\</body>
        \\</html>
        \\
    , .{node.content});
}
const h1 = .{ "<h1>", "</h1>\n" };
const h2 = .{ "<h2>", "</h2>\n" };
const h3 = .{ "<h3>", "</h3>\n" };
const h4 = .{ "<h4>", "</h4>\n" };
const h5 = .{ "<h5>", "</h5>\n" };
const h6 = .{ "<h6>", "</h6>\n" };
const bold = .{ "<b>", "</b>" };
const italic = .{ "<i>", "</i>" };
const unordered_list = .{ "<ul>", "</ul>" };
const ordered_list = .{ "<ol>", "</ol>" };
const list_item = .{ "<li>", "</li>" };
const code = .{ "<span style=\"font-family: Monospace\">", "</span>" };
const paragraph = .{ "\n<p>", "</p>\n" };
const default = .{ "", "" };

/// Default fragments. Pass this to `Zmd.toHtml` or provide your own.
/// Formatters can be functions receiving an allocator, the current node, and the rendered
/// content, or a 2-element tuple containing the open and close for each node.
pub const Fragments = struct {
    pub const root = Fragment.root;

    pub const block = Fragment.block;

    pub const link = Fragment.link;

    pub const image = Fragment.image;

    pub const h1 = Fragment.h1;
    pub const h2 = Fragment.h2;
    pub const h3 = Fragment.h3;
    pub const h4 = Fragment.h4;
    pub const h5 = Fragment.h5;
    pub const h6 = Fragment.h6;
    pub const bold = Fragment.bold;
    pub const italic = Fragment.italic;
    pub const unordered_list = .{ "<ul>", "</ul>" };
    pub const ordered_list = .{ "<ol>", "</ol>" };
    pub const list_item = .{ "<li>", "</li>" };
    pub const code = .{ "<span style=\"font-family: Monospace\">", "</span>" };
    pub const paragraph = .{ "\n<p>", "</p>\n" };
    pub const default = .{ "", "" };
};

/// Escape HTML entities.
pub fn escape(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    const replacements = .{
        .{ "&", "&amp;" },
        .{ "<", "&lt;" },
        .{ ">", "&gt;" },
    };

    var output = input;
    inline for (replacements) |replacement| {
        output = try std.mem.replaceOwned(u8, allocator, output, replacement[0], replacement[1]);
    }
    return output;
}
