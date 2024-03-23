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
    linebreak,
    none,
    eof,
};

pub const Element = struct {
    type: ElementType,
    syntax: []const u8 = "",
    close: ElementType = .none,
};

pub const elements = [_]Element{
    .{ .type = .h6, .syntax = "######", .close = .linebreak },
    .{ .type = .h5, .syntax = "#####", .close = .linebreak },
    .{ .type = .h4, .syntax = "####", .close = .linebreak },
    .{ .type = .h3, .syntax = "###", .close = .linebreak },
    .{ .type = .h2, .syntax = "##", .close = .linebreak },
    .{ .type = .h1, .syntax = "#", .close = .linebreak },
    .{ .type = .bold, .syntax = "**", .close = .bold },
    .{ .type = .italic, .syntax = "_", .close = .italic },
    .{ .type = .block, .syntax = "```", .close = .block },
    .{ .type = .code, .syntax = "`", .close = .code },
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
