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
        .paragraph => if (level == 1)
            getFormatterComptime(fragments, "paragraph")
        else
            getFormatterComptime(fragments, "text"),
        inline else => |element_type| getFormatterComptime(fragments, @tagName(element_type)),
    };

    var buf = std.ArrayList(u8).init(allocator);
    const buf_writer = buf.writer();

    switch (self.token.element.type) {
        .text => {
            if (self.children.items.len == 0) {
                try buf_writer.writeAll(try html.escape(allocator, input[self.token.start..self.token.end]));
            } else {
                try buf_writer.writeAll(input[self.token.start..self.token.end]);
            }
        },
        .code, .block => {
            try buf_writer.writeAll(try html.escape(allocator, self.content));
        },
        else => {},
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

/// Try to find a formatter from the provided fragments struct, fall back to defaults.
pub fn getFormatterComptime(fragments: type, comptime element_type: []const u8) Formatter {
    const formatter = if (@hasDecl(fragments, element_type))
        @field(fragments, element_type)
    else if (@hasDecl(html.DefaultFragments, element_type))
        @field(html.DefaultFragments, element_type)
    else
        html.DefaultFragments.default;

    return switch (@typeInfo(@TypeOf(formatter))) {
        .Fn => Formatter{ .function = &formatter },
        .Struct => Formatter{ .array = formatter },
        else => unreachable,
    };
}

/// Same as `getFormatterComptime` but does not require a comptime argument.
pub fn getFormatter(fragments: type, element_type: []const u8) Formatter {
    inline for (@typeInfo(fragments).@"struct".decls) |decl| {
        if (std.mem.eql(u8, decl.name, element_type)) {
            return makeFormatter(fragments, decl.name);
        }
    }

    inline for (@typeInfo(html.DefaultFragments).@"struct".decls) |decl| {
        if (std.mem.eql(u8, decl.name, element_type)) {
            return makeFormatter(html.DefaultFragments, decl.name);
        }
    }

    return makeFormatter(html.DefaultFragments, "default");
}

fn makeFormatter(fragments: type, comptime decl: []const u8) Formatter {
    const formatter = @field(fragments, decl);
    return switch (@typeInfo(@TypeOf(formatter))) {
        .@"fn" => Formatter{ .function = &formatter },
        .@"struct" => Formatter{ .array = formatter },
        else => unreachable,
    };
}

const Formatter = union(enum) {
    function: FormatFunction,
    array: FormatArray,
};

const FormatFunction = *const fn (std.mem.Allocator, Node) anyerror![]const u8;
const FormatArray = [2][]const u8;
