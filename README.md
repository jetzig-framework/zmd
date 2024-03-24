# Zmd

_Zmd_ is a [Markdown](https://en.wikipedia.org/wiki/Markdown) parser and _HTML_ translator written in 100% pure [Zig](https://ziglang.org/) with zero dependencies.

_Zmd_ is currently very incomplete and in alpha stage. It is used by the [Jetzig web framework](https://www.jetzig.dev/) and will be extended as features are needed.

## Usage

```zig
const std = @import("std");

const Zmd = @import("zmd").Zmd;
const fragments = @import("zmd").html.DefaultFragments;

pub fn main() !void {
    var zmd = Zmd.init(std.testing.allocator);
    defer zmd.deinit();

    try zmd.parse(
        \\# Header
        \\## Sub-header
        \\### Sub-sub-header
        \\
        \\some text in **bold** and _italic_
        \\
        \\a paragraph
        \\
        \\```zig
        \\some code
        \\```
        \\some more text with a `code` fragment
    );

    const html = try zmd.toHtml(fragments);
    defer std.testing.allocator.free(html);
}
```

### Customization

The default _HTML_ formatter provides a set of fragments that can be overridden. Fragments can be either:

* A two-element tuple containing an open and close tag (e.g. `.{ "<div>", </div>" }`);
* A function that receives `std.mem.Allocator` and `zmd.Node`, returning `![]const u8`.

Simply define a struct with the appropriate declarations of either type and _Zmd_ will use the provided fragments, falling back to defaults for anything that is not defined.

Some node types provie special attributes such as:

* `meta` - provided on `block` elements. This is the language specifier (`zig`) in this example:
````
```zig
if (true) std.debug.print("some zig code");
```
````
* `href`, `title` - provided on `image` and `link` elements.

```zig
const MyFragments = struct {
    pub const h1 = .{ "<h1 class='text-xl font-bold'>", "</h1>\n" };

    pub fn block(allocator: std.mem.Allocator, node: Node) ![]const u8 {
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
}
```

And then:

```zig
const html = try zmd.toHtml(MyFragments);
```

See [src/zmd/html.zig](src/zmd/html.zig) for the full reference.

## License

_Zmd_ is [MIT](LICENSE)-licensed.
