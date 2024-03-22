pub const Element = struct {
    type: enum {
        text,
        h6,
        h5,
        h4,
        h3,
        h2,
        h1,
    },
    syntax: []const u8,
    clear: bool,
};

pub const elements = [_]Element{
    .{ .type = .h6, .syntax = "######", .clear = true },
    .{ .type = .h5, .syntax = "#####", .clear = true },
    .{ .type = .h4, .syntax = "####", .clear = true },
    .{ .type = .h3, .syntax = "###", .clear = true },
    .{ .type = .h2, .syntax = "##", .clear = true },
    .{ .type = .h1, .syntax = "#", .clear = true },
};

pub const Text = Element{ .type = .text, .syntax = "", .clear = false };

pub const Token = struct {
    element: Element,
    start: usize,
    end: usize,
};
