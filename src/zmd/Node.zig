const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokens = @import("tokens.zig");
const Node = @This();
const Formatters = @import("Formatters.zig");
const Writer = std.Io.Writer;

token: tokens.Token,
content: []const u8 = "",
meta: ?[]const u8 = null,
href: ?[]const u8 = null,
title: ?[]const u8 = null,
children: ArrayList(*Node),
index: usize = 0,

/// Recursively translate a node into HTML.
pub fn toHtml(
    self: *Node,
    allocator: Allocator,
    input: []const u8,
    writer: *Writer,
    level: usize,
    formatters: Formatters,
) !void {
    const token_type = self.token.element.type;
    const formatter: ?*const Formatters.Handler = switch (token_type) {
        .linebreak, .none, .eof => null,
        .paragraph => if (level == 1)
            &getHandlerComptime(formatters, "paragraph")
        else
            &getHandlerComptime(formatters, "text"),
        inline else => |element_type| &getHandlerComptime(formatters, @tagName(element_type)),
    };

    var allocating: Writer.Allocating = .init(allocator);
    defer allocating.deinit();

    switch (token_type) {
        .text => {
            if (self.children.items.len == 0) {
                const escaped = try escape(
                    allocator,
                    input[self.token.start..self.token.end],
                );
                defer allocator.free(escaped);
                try allocating.writer.writeAll(escaped);
            } else {
                try allocating.writer.writeAll(
                    input[self.token.start..self.token.end],
                );
            }
        },
        .code, .block => {
            const escaped = try escape(allocator, self.content);
            defer allocator.free(escaped);
            try allocating.writer.writeAll(escaped);
        },
        else => {},
    }

    for (self.children.items) |node| {
        try node.toHtml(
            allocator,
            input,
            &allocating.writer,
            level + 1,
            formatters,
        );
    }

    self.content = if (self.token.element.trim)
        std.mem.trim(
            u8,
            try allocating.toOwnedSlice(),
            &std.ascii.whitespace,
        )
    else
        try allocating.toOwnedSlice();

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
