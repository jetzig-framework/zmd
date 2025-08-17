const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("Node.zig");
const Ast = @import("Ast.zig");
const tokens = @import("tokens.zig");
const html = @import("html.zig");
const Zmd = @This();

nodes: std.ArrayList(*Node),
state: enum { initial, parsed } = .initial,
input: []const u8 = undefined,

/// Initialize a new Zmd Markdown AST.
pub fn init(allocator: Allocator) !Zmd {
    const nodes: std.ArrayList(*Node) = try .initCapacity(allocator, 1);
    return .{ .nodes = nodes };
}

/// Deinitialize and free allocated memory.
pub fn deinit(self: *Zmd, allocator: Allocator) void {
    self.nodes.deinit(allocator);
}

/// Parse a Markdown string into an AST.
pub fn parse(self: *Zmd, allocator: Allocator, input: []const u8) !void {
    if (self.state != .initial) return error.NotInitial;

    const normalized = normalizeInput(allocator, input);
    var parser = try Ast.init(allocator, normalized);
    defer parser.deinit(allocator);

    try parser.tokenize(allocator);
    const root = try parser.parse(allocator);
    try self.nodes.append(allocator, root);

    self.input = normalized;
    self.state = .parsed;
}

/// Translate a parsed Markdown AST to HTML.
pub fn toHtml(self: *const Zmd, allocator: Allocator, fragments: type) ![]const u8 {
    if (self.state != .parsed) return error.NotInitialized;

    var buf: std.ArrayList(u8) = try .initCapacity(allocator, 1);
    const base_writer = buf.writer(allocator);
    //var bw: std.Io.Writer = .fixed(&buf.items);
    //const writer = bw.writer();

    try self.nodes.items[0].toHtml(allocator, self.input, fragments, base_writer, 0);

    //try bw.flush();

    return try allocator.dupe(u8, buf.items);
}

// Normalize text to unix-style linebreaks and ensure ending with a linebreak to simplify
// Windows compatibility.
fn normalizeInput(allocator: Allocator, input: []const u8) []const u8 {
    const output = std.mem.replaceOwned(u8, allocator, input, "\r\n", "\n") catch @panic("OOM");
    if (std.mem.endsWith(u8, output, "\n")) return output;

    return std.mem.concat(allocator, u8, &[_][]const u8{ output, "\n" }) catch @panic("OOM");
}
