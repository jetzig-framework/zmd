const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;
const Writer = std.Io.Writer;

pub const Node = @import("zmd/Node.zig");
pub const Ast = @import("zmd/Ast.zig");
pub const tokens = @import("zmd/tokens.zig");
pub const Formatters = @import("zmd/Formatters.zig");

pub fn parse(
    allocator: Allocator,
    markdown: []const u8,
    formatters: Formatters,
) ![]const u8 {
    var arena: ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var nodes: ArrayList(*Node) = try .initCapacity(alloc, 0);
    defer nodes.deinit(alloc);

    const normalized = normalizeInput(alloc, markdown);
    var ast: Ast = try .init(alloc, normalized);

    try ast.tokenize(alloc);
    const root = try ast.parse(alloc);
    try nodes.append(alloc, root);

    var allocating: Writer.Allocating = .init(alloc);
    defer allocating.deinit();

    try nodes.items[0].toHtml(
        alloc,
        markdown,
        // writer,
        &allocating.writer,
        0,
        formatters,
    );

    // return allocator.dupe(u8, buf.items);
    return allocator.dupe(u8, try allocating.toOwnedSlice());
}

// Normalize text to unix-style linebreaks and ensure ending with a linebreak to simplify
// Windows compatibility.
fn normalizeInput(allocator: Allocator, input: []const u8) []const u8 {
    const output = std.mem.replaceOwned(u8, allocator, input, "\r\n", "\n") catch @panic("OOM");
    if (std.mem.endsWith(u8, output, "\n")) return output;

    return std.mem.concat(allocator, u8, &[_][]const u8{ output, "\n" }) catch @panic("OOM");
}
test {
    _ = @import("tests.zig");
}
