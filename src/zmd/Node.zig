const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokens = @import("tokens.zig");
const Node = @This();
const Formatters = @import("Formatters.zig");

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
    formatters: Formatters,
) !void {
    const formatter: ?*const Formatters.Handler = switch (self.token.element.type) {
        .linebreak, .none, .eof => null,
        .paragraph => if (level == 1)
            &getHandlerComptime(formatters, "paragraph")
        else
            &getHandlerComptime(formatters, "text"),
        inline else => |element_type| &getHandlerComptime(formatters, @tagName(element_type)),
    };

    var buf: ArrayList(u8) = try .initCapacity(allocator, 1);
    defer buf.deinit(allocator);
    const buf_writer = buf.writer(allocator);

    switch (self.token.element.type) {
        .text => {
            if (self.children.items.len == 0) {
                const escaped = try escape(
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
            const escaped = try escape(allocator, self.content);
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
            formatters,
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
    formatters: Formatters,
    comptime element_type: []const u8,
) Formatters.Handler {
    return if (@hasField(Formatters, element_type))
        @field(formatters, element_type)
    else
        formatters.default;
}

fn escape(allocator: Allocator, input: []const u8) ![]const u8 {
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
