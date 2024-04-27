const std = @import("std");

pub const ElementType = enum {
    root,
    text,
    paragraph,
    h6,
    h5,
    h4,
    h3,
    h2,
    h1,
    bold,
    bold_close,
    italic,
    italic_close,
    block,
    block_close,
    code,
    code_close,
    image,
    link,
    image_title,
    link_title,
    title_close,
    href,
    href_close,
    ordered_list,
    unordered_list,
    ordered_list_item,
    unordered_list_item,
    list_item,
    linebreak,
    none,
    eof,
    container,
};

pub const Element = struct {
    type: ElementType,
    syntax: []const u8 = "",
    close: ElementType = .none,
    after: ?ElementType = null,
    expect: ?ElementType = null,
    trim: bool = false,
    clear: bool = false,
};

pub const elements = [_]Element{
    .{ .type = .h6, .syntax = "######", .close = .linebreak, .trim = true, .clear = true },
    .{ .type = .h5, .syntax = "#####", .close = .linebreak, .trim = true, .clear = true },
    .{ .type = .h4, .syntax = "####", .close = .linebreak, .trim = true, .clear = true },
    .{ .type = .h3, .syntax = "###", .close = .linebreak, .trim = true, .clear = true },
    .{ .type = .h2, .syntax = "##", .close = .linebreak, .trim = true, .clear = true },
    .{ .type = .h1, .syntax = "#", .close = .linebreak, .trim = true, .clear = true },
    .{ .type = .block, .syntax = "```", .close = .block_close, .clear = true },
    .{ .type = .code, .syntax = "`", .close = .code_close },
    .{ .type = .image_title, .syntax = "![", .close = .title_close },
    .{ .type = .link_title, .syntax = "[", .close = .title_close },
    .{ .type = .title_close, .syntax = "]" },
    .{ .type = .href, .syntax = "(", .close = .href_close, .after = .title_close },
    .{ .type = .href_close, .syntax = ")", .expect = .href },
    .{ .type = .unordered_list_item, .syntax = "+ ", .close = .linebreak, .clear = true },
    .{ .type = .unordered_list_item, .syntax = "* ", .close = .linebreak, .clear = true },
    .{ .type = .unordered_list_item, .syntax = "- ", .close = .linebreak, .clear = true },
    .{ .type = .ordered_list_item, .syntax = "1. ", .close = .linebreak, .clear = true },
};

pub const toggles = if (@hasDecl(std, "ComptimeStringMap"))
    std.ComptimeStringMap(
        Element,
        .{
            .{ "code", .{ .type = .code_close, .syntax = "`" } },
            .{ "block", .{ .type = .block_close, .syntax = "```" } },
        },
    )
else if (@hasDecl(std, "StaticStringMap"))
    std.StaticStringMap(Element).initComptime(
        .{
            .{ "code", .{ .type = .code_close, .syntax = "`" } },
            .{ "block", .{ .type = .block_close, .syntax = "```" } },
        },
    )
else
    unreachable;

pub const formatters = [_]Element{
    .{ .type = .bold, .syntax = "**", .close = .bold_close },
    .{ .type = .italic, .syntax = "_", .close = .italic_close },
};

pub const Linebreak = Element{ .type = .linebreak };
pub const Root = Element{ .type = .root, .close = .eof };
pub const Text = Element{ .type = .text, .close = .none };
pub const Paragraph = Element{ .type = .paragraph, .close = .linebreak };

pub const Token = struct {
    element: Element,
    start: usize,
    end: usize,
};
