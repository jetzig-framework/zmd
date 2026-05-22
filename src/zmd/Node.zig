const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokens = @import("tokens.zig");
const Node = @This();
const Config = @import("Config.zig");
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
    config: Config,
) !void {
    const token_type = self.token.element.type;
    const Fn: ?Config.Fn = switch (token_type) {
        .linebreak, .none, .eof => null,
        .paragraph => if (level == 1) config.paragraph
            // &getHandlerComptime(config, "paragraph")
        else config.text,
        // &getHandlerComptime(config, "text"),

        inline else => |element_type| getHandlerComptime(config, @tagName(element_type)),
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
            config,
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

    if (Fn) |func| {
        const html_string = try func(allocator, self.*);
        defer allocator.free(html_string);
        try writer.writeAll(html_string);
    }
}

pub fn getHandlerComptime(
    config: Config,
    comptime element_type: []const u8,
) Config.Fn {
    return if (@hasField(Config, element_type))
        @field(config, element_type)
    else
        config.text;
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
