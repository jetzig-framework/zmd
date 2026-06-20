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
Formatter for supported markdown elements can be overridden with fuctions:
```zig
const html = zmd.parseAlloc(alloc, markdown, .{
    .block = myBlock,
})
```
The function signature for formatters is `fn (*Writer, Node) !void`

Node provides special attributes such as:

* `meta` - provided on `block` elements. This is the language specifier (`zig`) in this example:
```zig
if (true) std.debug.print("some zig code");
```
* `href`, `title` - provided on `image` and `link` elements.



```zig
fn myBlock(writer: *Writer, node: zmd.Node) !void {
    // writer writes opening string
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

    // content is parsed and written

    // closing string
    return
    \\
    \\</code>
    \\</pre>
    \\
    ;
}
```

See [Config.zig](./src/Config.zig) for the full reference.

## License

_Zmd_ is [MIT](LICENSE)-licensed.
