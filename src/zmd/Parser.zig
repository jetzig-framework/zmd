const std = @import("std");
const Node = @import("Node.zig");
const tokens = @import("tokens.zig");

const Parser = @This();

allocator: std.mem.Allocator,
input: []const u8,
tokens: std.ArrayList(tokens.Token),
state: enum { initial, tokenized, parsed } = .initial,
current_node: *Node = undefined,
visited: std.AutoHashMap(usize, bool) = undefined,

/// Initialize a new parser.
pub fn init(allocator: std.mem.Allocator, input: []const u8) Parser {
    return .{
        .allocator = allocator,
        .input = input,
        .tokens = std.ArrayList(tokens.Token).init(allocator),
    };
}

/// Deinitialize and free allocated memory.
pub fn deinit(self: *Parser) void {
    self.tokens.deinit();
}

/// Parse tokenized input. Must call `tokenize()` first.
pub fn parse(self: *Parser) !*Node {
    if (self.state != .tokenized) unreachable;

    const root = try self.createNode(
        .{ .element = tokens.Root, .start = 0, .end = self.input.len },
    );

    self.visited = std.AutoHashMap(usize, bool).init(self.allocator);

    _ = try self.parseChildNodes(0, root);

    // debugTree(root, 0);

    self.state = .parsed;

    return root;
}

/// Iterate through input, separating into tokens to be fed to the parser.
pub fn tokenize(self: *Parser) !void {
    if (self.state != .initial) unreachable;

    var index: usize = 0;

    var previous_token: ?tokens.Token = null;

    try self.tokens.append(.{ .element = tokens.Root, .start = 0, .end = 0 });

    while (index < self.input.len) {
        if (self.firstToken(index)) |token| {
            if (previous_token) |prev_token| {
                if (prev_token.end < token.start) {
                    if (prev_token.element.type == .linebreak or prev_token.element.type == .root) {
                        try self.tokens.append(.{
                            .element = tokens.Paragraph,
                            .start = token.start,
                            .end = token.end,
                        });
                        try self.appendText(prev_token.end, token.start);
                    } else {
                        try self.appendText(prev_token.end, token.start);
                    }
                }
            }
            try self.tokens.append(token);
            previous_token = token;
            index = token.end;
        } else index += 1;
    }

    if (self.tokens.items.len > 0) {
        const last_token = self.tokens.items[self.tokens.items.len - 1];
        if (last_token.end < self.input.len - 1) {
            try self.appendText(last_token.end, self.input.len);
        }
    }

    try self.tokens.append(.{
        .element = .{ .type = .eof },
        .start = self.input.len,
        .end = self.input.len,
    });

    self.state = .tokenized;
}

// Return the first token in the input from the given index.
fn firstToken(self: Parser, index: usize) ?tokens.Token {
    if (self.input[index] == '\n') {
        return .{ .element = tokens.Linebreak, .start = index, .end = index + 1 };
    }

    for (tokens.elements) |element| {
        if (index + element.syntax.len > self.input.len) continue;
        if (std.mem.eql(u8, element.syntax, self.input[index .. index + element.syntax.len])) {
            return .{ .element = element, .start = index, .end = index + element.syntax.len };
        }
    }

    return null;
}

// Recursively build a tree of nodes from the given token index and a provided root node.
fn parseChildNodes(self: *Parser, start: usize, node: *Node) !bool {
    if (try self.visited.fetchPut(start, true)) |_| return false;
    var index = start;
    const end = self.getCloseIndex(index) orelse index;
    while (index < end) {
        const child_node = try self.createNode(self.tokens.items[index + 1]);
        index += 1;
        if (index >= self.tokens.items.len - 1) break;
        if (try self.parseChildNodes(index, child_node)) {
            try node.children.append(child_node);
        }
    }
    return true;
}

fn getCloseIndex(self: Parser, start: usize) ?usize {
    if (start >= self.tokens.items.len - 1) return null;
    const match_token = self.tokens.items[start];
    if (match_token.element.close == .none) return null;

    for (self.tokens.items[start + 1 ..], 1..) |token, index| {
        if (token.element.type == match_token.element.close) return index + start;
    }

    return null;
}
// Append a text node to the tree.
fn appendText(self: *Parser, start: usize, end: usize) !void {
    try self.tokens.append(.{
        .element = tokens.Text,
        .start = start,
        .end = end,
    });
}

// Create a new node on the heap.
fn createNode(self: Parser, token: tokens.Token) !*Node {
    const node = try self.allocator.create(Node);
    node.* = .{
        .token = token,
        .children = std.ArrayList(*Node).init(self.allocator),
    };
    return node;
}

// Output a parsed tree with indentation to stderr.
fn debugTree(node: *Node, level: usize) void {
    for (0..level) |_| std.debug.print(" ", .{});
    std.debug.print("{s}\n", .{@tagName(node.token.element.type)});
    for (node.children.items) |child_node| {
        debugTree(child_node, level + 1);
    }
}
