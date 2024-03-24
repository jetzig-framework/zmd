const std = @import("std");

const tokens = @import("tokens.zig");
const Node = @import("Node.zig");

/// Default fragments. Pass this to `Zmd.toHtml` or provide your own.
/// Formatters can be functions receiving an allocator, the current node, and the rendered
/// content, or a 2-element tuple containing the open and close for each node.
pub const DefaultFragments = struct {
    pub fn root(allocator: std.mem.Allocator, node: Node, content: []const u8) ![]const u8 {
        _ = node;
        return try std.fmt.allocPrint(allocator,
            \\<!DOCTYPE html>
            \\<html>
            \\<body>
            \\<main>{s}</main>
            \\</body>
            \\</html>
            \\
        , .{content});
    }

    pub fn block(allocator: std.mem.Allocator, node: Node, content: []const u8) ![]const u8 {
        const style = "font-family: Monospace;";

        return if (node.meta) |meta|
            std.fmt.allocPrint(allocator,
                \\<pre class="language-{s}" style="{s}"><code>{s}</code></pre>
            , .{ meta, style, content })
        else
            std.fmt.allocPrint(allocator,
                \\<pre style="{s}"><code>{s}</code></pre>
            , .{ style, content });
    }

    pub const h1 = .{ "<h1>", "</h1>\n" };
    pub const h2 = .{ "<h2>", "</h2>\n" };
    pub const h3 = .{ "<h3>", "</h3>\n" };
    pub const h4 = .{ "<h4>", "</h4>\n" };
    pub const h5 = .{ "<h5>", "</h5>\n" };
    pub const h6 = .{ "<h6>", "</h6>\n" };
    pub const text = .{ "", "" };
    pub const bold = .{ "<b>", "</b>" };
    pub const italic = .{ "<i>", "</i>" };
    pub const code = .{ "<span style=\"font-family: Monospace\">", "</span>" };
    pub const paragraph = .{ "<p>", "</p>\n" };
};