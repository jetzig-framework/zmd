const std = @import("std");

const tokens = @import("tokens.zig");
const html = @import("html.zig");

const Node = @This();

token: tokens.Token,
content: []const u8 = "",
children: std.ArrayList(*Node),
index: usize = 0,

/// Recursively translate a node into HTML.
pub fn toHtml(
    self: Node,
    allocator: std.mem.Allocator,
    input: []const u8,
    fragments: type,
    writer: anytype,
    level: usize,
) !void {
    const formatter = switch (self.token.element.type) {
        .linebreak, .none, .eof => null,
        .paragraph => if (level == 1) getFormatter(fragments, "paragraph") else getFormatter(fragments, "text"),
        inline else => |element_type| getFormatter(fragments, @tagName(element_type)),
    };

    if (formatter) |capture| {
        if (self.children.items.len > 0) try writer.writeAll(capture[0]);
    }

    if (self.token.element.type == .text) {
        try writer.writeAll(input[self.token.start..self.token.end]);
    }

    for (self.children.items) |node| {
        try node.toHtml(allocator, input, fragments, writer, level + 1);
    }

    if (formatter) |capture| {
        if (self.children.items.len > 0) try writer.writeAll(capture[1]);
    }
}

// Try to find a formatter from the provided fragments struct, fall back to defaults.
fn getFormatter(fragments: type, comptime element_type: []const u8) [2][]const u8 {
    if (@hasDecl(fragments, element_type)) return @field(fragments, element_type);
    return @field(html.DefaultFragments, element_type);
}
