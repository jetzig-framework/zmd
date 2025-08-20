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

### Customization
Formatter for supported markdown elements can be overridden with fuctions:
```zig
const html = zmd.parse(alloc, markdown, .{
    .block = myBlock,
})

```
The function signature for formatters is `fn (Allocator, Node) ![]const u8`

Some node types provie special attributes such as:

* `meta` - provided on `block` elements. This is the language specifier (`zig`) in this example:
```zig
if (true) std.debug.print("some zig code");
```
* `href`, `title` - provided on `image` and `link` elements.

```zig
fn myBlock(allocator: std.mem.Allocator, node: zmd.Node) ![]const u8 {
    const style = "font-family: Monospace;";

    return if (node.meta) |meta|
        std.fmt.allocPrint(allocator,
            \\<pre class="language-{s}" style="{s}"><code>{s}</code></pre>
        , .{ meta, style, node.content })
    else
        std.fmt.allocPrint(allocator,
            \\<pre style="{s}"><code>{s}</code></pre>
        , .{ style, node.content });
}
```

See [src/zmd/Handlers.zig](src/zmd/Handlers.zig) for the full reference.

## License

_Zmd_ is [MIT](LICENSE)-licensed.
