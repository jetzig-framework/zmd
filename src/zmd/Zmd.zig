const std = @import("std");

const Node = @import("Node.zig");
const Ast = @import("Ast.zig");
const tokens = @import("tokens.zig");
const html = @import("html.zig");

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
nodes: std.ArrayList(*Node),
state: enum { initial, parsed } = .initial,
input: []const u8 = undefined,

const Zmd = @This();

/// Initialize a new Zmd Markdown AST.
pub fn init(allocator: std.mem.Allocator) Zmd {
    return .{
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .nodes = (std.ArrayList(*Node).initCapacity(allocator, 0) catch unreachable),
    };
}

/// Deinitialize and free allocated memory.
pub fn deinit(self: *Zmd) void {
    self.nodes.deinit(self.allocator);
    self.arena.deinit();
}

/// Parse a Markdown string into an AST.
pub fn parse(self: *Zmd, input: []const u8) !void {
    if (self.state != .initial) unreachable;

    const allocator = self.arena.allocator();

    const normalized = normalizeInput(allocator, input);

    var parser = Ast.init(allocator, normalized);
    defer parser.deinit();

    try parser.tokenize();

    const root = try parser.parse();
    try self.nodes.append(self.allocator, root);

    self.input = normalized;

    self.state = .parsed;
}

/// Translate a parsed Markdown AST to HTML.
pub fn toHtml(self: *const Zmd, fragments: type) ![]const u8 {
    if (self.state != .parsed) unreachable;

    var arena: std.heap.ArenaAllocator = .init(self.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var buffer: std.ArrayList(u8) = try .initCapacity(allocator, 0);
    defer buffer.deinit(allocator);
    var bw: std.Io.Writer.Allocating = .fromArrayList(allocator, &buffer);
    defer bw.deinit();

    try self.nodes.items[0].toHtml(allocator, self.input, fragments, &bw.writer, 0);

    return self.allocator.dupe(u8, buffer.items);
}

// Normalize text to unix-style linebreaks and ensure ending with a linebreak to simplify
// Windows compatibility.
fn normalizeInput(allocator: std.mem.Allocator, input: []const u8) []const u8 {
    const output = std.mem.replaceOwned(u8, allocator, input, "\r\n", "\n") catch @panic("OOM");
    if (std.mem.endsWith(u8, output, "\n")) return output;

    return std.mem.concat(allocator, u8, &[_][]const u8{ output, "\n" }) catch @panic("OOM");
}
