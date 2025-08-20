const std = @import("std");
const Node = @import("Node.zig");
const Formatters = @This();
const Allocator = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;
pub const Handler = fn (Allocator, Node) Allocator.Error![]const u8;

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
    pub fn root(allocator: Allocator, node: Node) ![]const u8 {
        const html =
            \\<!DOCTYPE html>
            \\<html>
            \\<body>
            \\<main>{s}</main>
            \\</body>
            \\</html>
            \\
        ;
        return allocPrint(allocator, html, .{node.content});
    }

    pub fn block(allocator: Allocator, node: Node) ![]const u8 {
        const style = "font-family: Monospace;";
        return if (node.meta) |meta|
            allocPrint(
                allocator,
                "<pre class=\"language-{s}\" style=\"{s}\"><code>{s}</code></pre>",
                .{ meta, style, node.content },
            )
        else
            allocPrint(
                allocator,
                "<pre style=\"{s}\"><code>{s}</code></pre>",
                .{ style, node.content },
            );
    }

    pub fn link(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(
            allocator,
            "<a href=\"{s}\">{s}</a>",
            .{ node.href.?, node.title.? },
        );
    }

    pub fn image(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(
            allocator,
            "<img src=\"{s}\" title=\"{s}\" />",
            .{ node.href.?, node.title.? },
        );
    }

    pub fn h1(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(allocator, "<h1>{s}</h1>\n", .{node.content});
    }

    pub fn h2(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(allocator, "<h2>{s}</h2>\n", .{node.content});
    }

    pub fn h3(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(allocator, "<h3>{s}</h3>\n", .{node.content});
    }

    pub fn h4(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(allocator, "<h4>{s}</h4>\n", .{node.content});
    }

    pub fn h5(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(allocator, "<h5>{s}</h5>\n", .{node.content});
    }

    pub fn h6(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(allocator, "<h6>{s}</h6>\n", .{node.content});
    }

    pub fn bold(allocator: Allocator, node: Node) ![]const u8 {
        return wrap(allocator, node.content, "b");
    }

    pub fn italic(allocator: Allocator, node: Node) ![]const u8 {
        return wrap(allocator, node.content, "i");
    }

    pub fn unordered_list(allocator: Allocator, node: Node) ![]const u8 {
        return wrap(allocator, node.content, "ul");
    }

    pub fn ordered_list(allocator: Allocator, node: Node) ![]const u8 {
        return wrap(allocator, node.content, "ol");
    }

    pub fn list_item(allocator: Allocator, node: Node) ![]const u8 {
        return wrap(allocator, node.content, "li");
    }

    pub fn code(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(
            allocator,
            "<span style=\"font-family: Monospace\">{s}</span>",
            .{node.content},
        );
    }

    pub fn paragraph(allocator: Allocator, node: Node) ![]const u8 {
        return allocPrint(
            allocator,
            "\n<p>{s}</p>\n",
            .{node.content},
        );
    }

    pub fn default(allocator: Allocator, node: Node) ![]const u8 {
        _ = allocator;
        return node.content;
    }
};

fn wrap(allocator: Allocator, content: []const u8, string: []const u8) ![]const u8 {
    return allocPrint(
        allocator,
        "<{s}>{s}</{s}>",
        .{ string, content, string },
    );
}
