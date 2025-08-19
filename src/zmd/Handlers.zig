const std = @import("std");
const Node = @import("Node.zig");
const Handlers = @This();
const Allocator = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;
const FragmentHandler = fn (Allocator, Node) Allocator.Error![]const u8;

root: FragmentHandler = Default.root,
block: FragmentHandler = Default.block,
link: FragmentHandler = Default.link,
image: FragmentHandler = Default.image,
h1: FragmentHandler = Default.header,
h2: FragmentHandler = Default.header,
h3: FragmentHandler = Default.header,
h4: FragmentHandler = Default.header,
h5: FragmentHandler = Default.header,
h6: FragmentHandler = Default.header,
bold: FragmentHandler = Default.bold,
italic: FragmentHandler = Default.italic,
unordered_list: FragmentHandler = Default.unordered_list,
ordered_list: FragmentHandler = Default.ordered_list,
list_item: FragmentHandler = Default.list_item,
code: FragmentHandler = Default.code,
paragraph: FragmentHandler = Default.paragraph,
default: FragmentHandler = Default.default,

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

    pub fn header(allocator: Allocator, node: Node) ![]const u8 {
        const tag = @tagName(node.token.element.type);
        return wrap(allocator, node.content, tag);
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
        "<s>{s}</s>",
        .{ string, content, string },
    );
}
