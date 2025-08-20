const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
pub const Node = @import("Node.zig");
const Ast = @import("Ast.zig");
const ArrayList = std.ArrayList;
//const tokens = @import("tokens.zig");
//const html = @import("html.zig");
//const Zmd = @This();
const Handlers = @import("Handlers.zig");

/// Parse a Markdown string into html. Caller owns returned memory
/// ```
/// const html = try Zmd.parse(alloc, markdown, .{
///     .h1 = someFunc,
///     .h2 = otherFunc,
/// });
/// defer alloc.free(html);
/// ```
/// Handler funcs should be `fn(Allocator, *Zmd.Node) anytype![]const u8`
pub fn parse(
    allocator: Allocator,
    input: []const u8,
    handlers: Handlers,
) ![]const u8 {
    // TODO: plumb in fragments to allow users to provide their own html
    // fragments.
    var arena: ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var nodes: ArrayList(*Node) = try .initCapacity(alloc, 0);
    defer nodes.deinit(alloc);

    const normalized = normalizeInput(alloc, input);
    var ast: Ast = try .init(alloc, normalized);

    try ast.tokenize(alloc);
    const root = try ast.parse(alloc);
    try nodes.append(alloc, root);

    var buf: ArrayList(u8) = try .initCapacity(alloc, 0);
    defer buf.deinit(alloc);

    // TODO: replace this with new std.Io.Writer
    const base_writer = buf.writer(alloc);
    try nodes.items[0].toHtml(
        alloc,
        input,
        base_writer,
        0,
        handlers,
    );

    return allocator.dupe(u8, buf.items);
}

// Normalize text to unix-style linebreaks and ensure ending with a linebreak to simplify
// Windows compatibility.
fn normalizeInput(allocator: Allocator, input: []const u8) []const u8 {
    const output = std.mem.replaceOwned(u8, allocator, input, "\r\n", "\n") catch @panic("OOM");
    if (std.mem.endsWith(u8, output, "\n")) return output;

    return std.mem.concat(allocator, u8, &[_][]const u8{ output, "\n" }) catch @panic("OOM");
}
