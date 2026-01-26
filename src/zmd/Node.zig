const std = @import("std");
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
    input: []const u8,
    writer: *Writer,
    level: usize,
    formatters: Formatters,
    trim_start: bool,
    trim_end: bool,
) Writer.Error!void {
    const token_type = self.token.element.type;
    const formatter: ?*const Formatters.Handler = switch (token_type) {
        .linebreak, .none, .eof => null,
        .paragraph => if (level == 1)
            &getHandlerComptime(formatters, "paragraph")
        else
            &getHandlerComptime(formatters, "text"),
        inline else => |element_type| &getHandlerComptime(formatters, @tagName(element_type)),
    };

    // Call formatter to write opening markup; get close tag.
    const close_tag: []const u8 = if (formatter) |handler_func|
        try handler_func(writer, self.*)
    else
        "";

    // Write own content directly to the writer.
    switch (token_type) {
        .text => {
            if (self.children.items.len == 0) {
                var content = input[self.token.start..self.token.end];
                if (trim_start) content = std.mem.trimLeft(u8, content, &std.ascii.whitespace);
                if (trim_end) content = std.mem.trimRight(u8, content, &std.ascii.whitespace);
                try writeEscaped(writer, content);
            }
        },
        .code, .block => {
            try writeEscaped(writer, self.content);
        },
        else => {},
    }

    // Recurse into children, writing directly to the same writer.
    const self_trim = self.token.element.trim;
    const len = self.children.items.len;
    for (self.children.items, 0..) |node, i| {
        try node.toHtml(
            input,
            writer,
            level + 1,
            formatters,
            (self_trim or trim_start) and i == 0,
            (self_trim or trim_end) and i == len - 1,
        );
    }

    // Write close tag.
    if (close_tag.len > 0) try writer.writeAll(close_tag);
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

fn writeEscaped(writer: *Writer, input: []const u8) Writer.Error!void {
    var start: usize = 0;
    for (input, 0..) |byte, i| {
        const replacement: ?[]const u8 = switch (byte) {
            '&' => "&amp;",
            '<' => "&lt;",
            '>' => "&gt;",
            '\r' => "",
            else => null,
        };
        if (replacement) |r| {
            if (i > start) try writer.writeAll(input[start..i]);
            try writer.writeAll(r);
            start = i + 1;
        }
    }
    if (start < input.len) try writer.writeAll(input[start..]);
}
