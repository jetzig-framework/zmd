const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;
const Writer = std.Io.Writer;

pub const Node = @import("zmd/Node.zig");
pub const Ast = @import("zmd/Ast.zig");
pub const tokens = @import("zmd/tokens.zig");
pub const Formatters = @import("zmd/Formatters.zig");

pub fn parseW(
    allocator: Allocator,
    writer: *Writer,
    input: []const u8,
    formatters: Formatters,
) !void {
    var arena: ArenaAllocator = .init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var nodes: ArrayList(*Node) = .empty;
    defer nodes.deinit(alloc);

    const normalized = try normalizeInput(alloc, input);
    var ast: Ast = try .init(alloc, normalized);
    defer ast.deinit(alloc);
    const root = try ast.parse(alloc);
    try nodes.append(alloc, root);

    try nodes.items[0].toHtml(
        normalized,
        writer,
        0,
        formatters,
        false,
        false,
    );
}

pub fn parse(
    allocator: Allocator,
    input: []const u8,
    formatters: Formatters,
) ![]const u8 {
    var aw: Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try parseW(allocator, &aw.writer, input, formatters);
    return aw.toOwnedSlice();
}

fn normalizeInput(allocator: Allocator, input: []const u8) ![]const u8 {
    if (input.len > 0 and input[input.len - 1] == '\n') return input;
    return std.mem.concat(allocator, u8, &[_][]const u8{ input, "\n" });
}

test {
    _ = @import("tests.zig");
}
