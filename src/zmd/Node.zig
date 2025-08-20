const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokens = @import("tokens.zig");
const html = @import("html.zig");
const Node = @This();
const Handlers = @import("Handlers.zig");

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
    allocator: Allocator,
    input: []const u8,
    writer: anytype,
    level: usize,
    handlers: Handlers,
) !void {
    const formatter: ?*const Handlers.Handler = switch (self.token.element.type) {
        .linebreak, .none, .eof => null,
        .paragraph => if (level == 1)
            &getHandlerComptime(handlers, "paragraph")
        else
            &getHandlerComptime(handlers, "text"),
        inline else => |element_type| &getHandlerComptime(handlers, @tagName(element_type)),
    };

    var buf: ArrayList(u8) = try .initCapacity(allocator, 1);
    defer buf.deinit(allocator);
    const buf_writer = buf.writer(allocator);

    switch (self.token.element.type) {
        .text => {
            if (self.children.items.len == 0) {
                const escaped = try html.escape(
                    allocator,
                    input[self.token.start..self.token.end],
                );
                defer allocator.free(escaped);
                try buf_writer.writeAll(escaped);
            } else {
                try buf_writer.writeAll(input[self.token.start..self.token.end]);
            }
        },
        .code, .block => {
            const escaped = try html.escape(allocator, self.content);
            defer allocator.free(escaped);
            try buf_writer.writeAll(escaped);
        },
        else => {},
    }

    for (self.children.items) |node| {
        try node.toHtml(
            allocator,
            input,
            buf_writer,
            level + 1,
            handlers,
        );
    }

    self.content = if (self.token.element.trim)
        std.mem.trim(u8, buf.items, &std.ascii.whitespace)
    else
        buf.items;

    if (formatter) |handler_func| {
        const html_string = try handler_func(allocator, self.*);
        defer allocator.free(html_string);
        try writer.writeAll(html_string);
    }
}

pub fn getHandlerComptime(
    handlers: Handlers,
    comptime element_type: []const u8,
) Handlers.Handler {
    return if (@hasField(Handlers, element_type))
        @field(handlers, element_type)
    else
        handlers.default;
}
