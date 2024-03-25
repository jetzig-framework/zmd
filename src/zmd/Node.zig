const std = @import("std");

const tokens = @import("tokens.zig");
const html = @import("html.zig");

const Node = @This();

token: tokens.Token,
content: []const u8 = "",
meta: ?[]const u8 = null,
href: ?[]const u8 = null,
title: ?[]const u8 = null,
children: std.ArrayList(*Node),
index: usize = 0,

/// Recursively translate a node into HTML.
pub fn toHtml(
    self: *Node,
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

    var buf = std.ArrayList(u8).init(allocator);
    const buf_writer = buf.writer();

    if (self.token.element.type == .text) {
        if (self.children.items.len == 0) {
            try buf_writer.writeAll(try html.escape(allocator, input[self.token.start..self.token.end]));
        } else {
            try buf_writer.writeAll(input[self.token.start..self.token.end]);
        }
    }

    for (self.children.items) |node| {
        try node.toHtml(allocator, input, fragments, buf_writer, level + 1);
    }

    self.content = if (self.token.element.trim)
        std.mem.trim(u8, buf.items, &std.ascii.whitespace)
    else
        buf.items;

    if (formatter) |capture| {
        switch (capture) {
            .function => |function| try writer.writeAll(try function(allocator, self.*)),
            .array => |array| {
                try writer.writeAll(array[0]);
                try writer.writeAll(self.content);
                try writer.writeAll(array[1]);
            },
        }
    }
}

// Try to find a formatter from the provided fragments struct, fall back to defaults.
fn getFormatter(fragments: type, comptime element_type: []const u8) Formatter {
    const formatter = if (@hasDecl(fragments, element_type))
        @field(fragments, element_type)
    else if (@hasDecl(html.DefaultFragments, element_type))
        @field(html.DefaultFragments, element_type)
    else
        html.DefaultFragments.default;

    switch (@typeInfo(@TypeOf(formatter))) {
        .Fn => return Formatter{ .function = &formatter },
        .Struct => return Formatter{ .array = formatter },
        else => unreachable,
    }
}

const Formatter = union(enum) {
    function: FormatFunction,
    array: FormatArray,
};

const FormatFunction = *const fn (std.mem.Allocator, Node) anyerror![]const u8;
const FormatArray = [2][]const u8;
