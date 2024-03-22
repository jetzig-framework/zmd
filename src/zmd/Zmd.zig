const std = @import("std");

const Node = @import("Node.zig");
const Parser = @import("Parser.zig");

allocator: std.mem.Allocator,
nodes: std.ArrayList(Node),

const Zmd = @This();

/// Initialize a new Zmd markdown AST.
pub fn init(allocator: std.mem.Allocator) Zmd {
    return .{
        .allocator = allocator,
        .nodes = std.ArrayList(Node).init(allocator),
    };
}

/// Deinitialize and free allocated memory.
pub fn deinit(self: *Zmd) void {
    self.nodes.deinit();
}

/// Parse a markdown string into an AST.
pub fn parse(self: *Zmd, input: []const u8) !void {
    var parser = Parser.init(self.allocator, input);
    defer parser.deinit();

    try parser.tokenize();

    // var root =
    for (parser.tokens.items) |token| {
        // switch (token.element.type) {
        //     .h1 => {},
        // }
        std.debug.print("type: {s}, token: {s}\n", .{ @tagName(token.element.type), input[token.start..token.end] });
        try self.nodes.append(.{ .content = "Header" });
    }
}

pub const ZmdIterator = struct {
    index: usize = 0,
    nodes: std.ArrayList(Node),

    pub fn next(self: *ZmdIterator) ?Node {
        if (self.index >= self.nodes.items.len) return null;
        const node = self.nodes.items[self.index];
        self.index += 1;
        return node;
    }
};

/// Return an iterator that walks the parsed AST and yields `?Zmd.Node`.
pub fn walk(self: *const Zmd) ZmdIterator {
    return .{ .nodes = self.nodes };
}
