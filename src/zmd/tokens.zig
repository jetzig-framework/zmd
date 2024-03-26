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
    italic,
    block,
    code,
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
};

pub const Element = struct {
    type: ElementType,
    syntax: []const u8 = "",
    close: ElementType = .none,
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
    .{ .type = .bold, .syntax = "**", .close = .bold },
    .{ .type = .italic, .syntax = "_", .close = .italic },
    .{ .type = .block, .syntax = "```", .close = .block, .clear = true },
    .{ .type = .code, .syntax = "`", .close = .code },
    .{ .type = .image_title, .syntax = "![", .close = .title_close },
    .{ .type = .link_title, .syntax = "[", .close = .title_close },
    .{ .type = .title_close, .syntax = "]" },
    .{ .type = .href, .syntax = "(", .close = .href_close },
    .{ .type = .href_close, .syntax = ")" },
    .{ .type = .unordered_list_item, .syntax = "+ ", .close = .linebreak, .clear = true },
    .{ .type = .unordered_list_item, .syntax = "* ", .close = .linebreak, .clear = true },
    .{ .type = .unordered_list_item, .syntax = "- ", .close = .linebreak, .clear = true },
    .{ .type = .ordered_list_item, .syntax = "1. ", .close = .linebreak, .clear = true },
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
