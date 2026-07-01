# Zmd

_Zmd_ is a [Markdown](https://en.wikipedia.org/wiki/Markdown) parser and _HTML_ translator written in 100% pure [Zig](https://ziglang.org/) with zero dependencies.

_Zmd_ is used by the [Jetzig web framework](https://www.jetzig.dev/).

## Supported syntax

* Headers (H1->H6)
* **bold**
* _italic_
* `code`
* Links
* Images
* Fenced code blocks (with info string)
* Ordered lists
* Unordered lists
* template blocks (`{{...}}`)

## Usage

```zig
const std = @import("std");
const zmd = @import("zmd");

pub fn main(init: std.process.Init) !void {
    const markdown =
        \\# Header
        \\## Sub-header
        \\### Sub-sub-header
        \\
        \\some text in **bold** and _italic_
        \\
        \\a paragraph
        \\
        \\```
        \\some code
        \\some more code in the same block
        \\and yet more code
        \\```
        \\some more text with a `code` fragment
        \\- list item
        \\  1. ordered item
    ;

    const stdout: std.Io.File = .stdout();
    var buf: [256]u8 = undefined;
    var writer = stdout.writer(init.io, &buf);
    try zmd.parseSlice(markdown, &writer.interface, .{});
}
```

### Customization

The HTML output for each markdown element is defined by a `Tag` - a pair of `opening` and `closing` strings. The default tags are in [Config.zig](./src/Config.zig).

Tags can be overridden at runtime by passing a `Config` value to the parse functions. Individual tags not specified fall back to the configured defaults:

```zig
const html = zmd.parseAlloc(alloc, markdown, .{
    .h1 = .{ .opening = "<h1 class=\"title\">", .closing = "</h1>\n" },
    .block = .{ .opening = "<pre><code>", .closing = "</code></pre>\n" },
});
```

## License

_Zmd_ is [MIT](LICENSE)-licensed.
