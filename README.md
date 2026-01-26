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

## Usage

```zig
const std = @import("std");
const zmd = @import("zmd");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const markdown = "# Header";

    const html = try zmd.parse(allocator, markdown, .{});
    defer allocator.free(html);

    const stdout = std.fs.File.stdout();
    try stdout.writeAll(html);
}
```

There is a `zmd.parseW()` function that allows you to supply your own writer, part of my ongoing effort to remove as many allocations as I can. `.parse()` currently is a wrapper around it that creates it's own allocating writer;

### Customization
Formatter for supported markdown elements can be overridden with functions:
```zig
const html = zmd.parse(alloc, markdown, .{
    .block = myBlockWriter,
})

```
The function signature for formatters is `fn (*Writer, Node) Writer.Error![]const u8`

Some node types provide special attributes such as:

* `href`, `title` - provided on `image` and `link` elements.
```zig
pub fn link(writer: *Writer, node: Node) Writer.Error![]const u8 {
    try writer.print(
        \\<a href="{s}">{s}</a>
    , .{ node.href.?, node.title.? });
    return "";
}

pub fn image(writer: *Writer, node: Node) Writer.Error![]const u8 {
    try writer.print(
        \\<img src="{s}" title="{s}">
    , .{ node.href.?, node.title.? });
    return "";
}
```

* `meta` - provided on `block` elements. This is the language specifier (`zig`) in this example:

```md
'''zig
if (true) std.debug.print("some zig code");
'''
```

```zig
pub fn myBlockWriter(writer: *Writer, node: Node) Writer.Error![]const u8 {

    // writer writes opening blocks, or in the cases like img, the entire tag
    try writer.writeAll(
        \\<pre style="font-family: Monospace;"
    );
    if (node.meta) |meta|
        try writer.print(
            \\ class="language-{s}"
        , .{meta});
    try writer.writeAll(
        \\>
        \\<code>
        \\
    );

    // Content is written in parser

    // Closing tags
    return 
    \\
    \\</code>
    \\</pre>
    \\
    ;
}
```

See [src/zmd/Formatters.zig](src/zmd/Formatters.zig) for the full reference.

## License

_Zmd_ is [MIT](LICENSE)-licensed.
