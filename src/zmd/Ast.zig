const std = @import("std");
const Node = @import("Node.zig");
const tokens = @import("tokens.zig");

const Ast = @This();

allocator: std.mem.Allocator,
input: []const u8,
tokens: std.ArrayList(tokens.Token),
state: enum { initial, tokenized, parsed } = .initial,
current_node: *Node = undefined,
visited: std.AutoHashMap(usize, bool) = undefined,

/// Initialize a new Ast.
pub fn init(allocator: std.mem.Allocator, input: []const u8) Ast {
    return .{
        .allocator = allocator,
        .input = input,
        .tokens = std.ArrayList(tokens.Token).init(allocator),
    };
}

/// Deinitialize and free allocated memory.
pub fn deinit(self: *Ast) void {
    self.tokens.deinit();
}

/// Parse tokenized input. Must call `tokenize()` first.
pub fn parse(self: *Ast) !*Node {
    if (self.state != .tokenized) unreachable;

    const root = try self.createNode(
        .{ .element = tokens.Root, .start = 0, .end = self.input.len },
    );

    self.visited = std.AutoHashMap(usize, bool).init(self.allocator);

    _ = try self.parseChildNodes(0, root);

    debugTree(root, 0);

    self.state = .parsed;

    return root;
}

/// Iterate through input, separating into tokens to be fed to the parser.
pub fn tokenize(self: *Ast) !void {
    if (self.state != .initial) unreachable;

    var index: usize = 0;

    var previous_token: ?tokens.Token = null;

    try self.tokens.append(.{ .element = tokens.Root, .start = 0, .end = 0 });

    while (index < self.input.len) {
        if (self.firstToken(index)) |token| {
            if (previous_token) |prev_token| try self.maybeTokenizeText(prev_token, token);
            if (!token.element.clear or (token.element.clear and self.isCleared(index))) {
                try self.tokens.append(token);
            }
            previous_token = token;
            index = token.end;
        } else index += 1;

        // Prepend a text node if the first token (after the root token) does not start at the
        // beginning of the input.
        if (self.tokens.items.len == 2 and self.tokens.items[1].start > 0) {
            try self.insertText(1, 0, self.tokens.items[1].start);
        }
    }

    if (self.tokens.items.len > 0) {
        const last_token = self.tokens.items[self.tokens.items.len - 1];
        // Append a text node for the remainder of the buffer if present:
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

// Detect if a given input index proceeds a linebreak (possibly with trailing whitespace), or if
// the cursor is at first character in the input.
fn isCleared(self: Ast, index: usize) bool {
    if (index == 0) return true;
    var cursor = index - 1;
    while (cursor >= 0) : (cursor -= 1) {
        if (!std.ascii.isWhitespace(self.input[cursor])) return false;
        if (self.input[cursor] == '\n') return true;
    }

    return false;
}

// Return the first token in the input from the given index.
fn firstToken(self: Ast, index: usize) ?tokens.Token {
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
fn parseChildNodes(self: *Ast, start: usize, node: *Node) !bool {
    if (try self.visited.fetchPut(start, true)) |_| return false;
    var index = start;
    const end = self.getCloseIndex(index) orelse index;
    while (index < end) {
        index += 1;
        const child_node = try self.createNode(self.tokens.items[index]);
        switch (child_node.token.element.type) {
            .link_title => self.parseLink(child_node, index, .link),
            .image_title => self.parseLink(child_node, index, .image),
            .block => self.parseBlock(child_node, index, self.getCloseIndex(index)),
            .unordered_list_item => try self.parseList(child_node, index, .unordered),
            .ordered_list_item => try self.parseList(child_node, index, .ordered),
            else => {},
        }
        self.nullifyToken(end);
        if (index >= self.tokens.items.len - 1) break;
        if (try self.parseChildNodes(index, child_node)) {
            if (child_node.token.element.type != .none) try node.children.append(child_node);
        }
    }
    return true;
}

/// Locate the token index for the syntax that closes the current token.
fn getCloseIndex(self: Ast, start: usize) ?usize {
    if (start >= self.tokens.items.len - 1) return null;
    const match_token = self.tokens.items[start];
    if (match_token.element.close == .none) return null;

    for (self.tokens.items[start + 1 ..], 1..) |token, index| {
        if (token.element.type == match_token.element.close) return index + start;
    }

    return null;
}

// Convert text into a paragraph if it proceeds a linebreak or the root node, otherwise add plain
// text (text is the generic token for anything that does not match another token type,
// e.g. `# Foo` is comprised of a `.h1` and a `.text` token.
fn maybeTokenizeText(self: *Ast, prev_token: tokens.Token, token: tokens.Token) !void {
    if (prev_token.end >= token.start) return;

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

// Append a text token to the end of the tokens array.
fn appendText(self: *Ast, start: usize, end: usize) !void {
    try self.tokens.append(.{
        .element = tokens.Text,
        .start = start,
        .end = end,
    });
}

// Insert a text token at the given index.
fn insertText(self: *Ast, index: usize, start: usize, end: usize) !void {
    try self.tokens.insert(index, .{
        .element = tokens.Text,
        .start = start,
        .end = end,
    });
}

// Translate a link/image title and href into a single node. Nullify dangling nodes.
fn parseLink(self: *Ast, node: *Node, index: usize, link_type: enum { image, link }) void {
    const expected_tokens = &[_]tokens.ElementType{ .text, .title_close, .href, .text, .href_close };
    if (index + expected_tokens.len + 1 >= self.tokens.items.len - 1) return self.swapText(node, index);

    for (expected_tokens, index + 1..) |expected, offset| {
        if (self.tokens.items[offset].element.type != expected) return self.swapText(node, index);
    }

    const start = node.token.start;
    const end = self.tokens.items[index + expected_tokens.len + 1].end;

    const element_type: tokens.ElementType = switch (link_type) {
        .image => .image,
        .link => .link,
    };

    node.token = .{ .element = .{ .type = element_type }, .start = start, .end = end };
    node.href = self.input[self.tokens.items[index + 4].start..self.tokens.items[index + 4].end];
    node.title = self.input[self.tokens.items[index + 1].start..self.tokens.items[index + 1].end];

    for (0..expected_tokens.len) |offset| self.nullifyToken(index + offset);
}

// Swap a given node with a plain text node. Used when a link/image token does not have the
// expected subsequent tokens to build a full link/image node.
fn swapText(self: Ast, node: *Node, index: usize) void {
    const token = self.tokens.items[index];
    node.token = .{ .element = tokens.Text, .start = token.start, .end = token.end };
}

// Append a meta value to a `block` node. Replace dangling text token with a `.none` element.
fn parseBlock(self: *Ast, node: *Node, index: usize, maybe_end: ?usize) void {
    const end = maybe_end orelse return; // We don't have a closing ``` so don't try to parse
    if (index + 2 >= self.tokens.items.len) return;

    const next_token = self.tokens.items[index + 1];
    const has_meta = next_token.element.type == .text;

    // meta is the "zig" in ```zig
    if (has_meta) {
        node.meta = self.input[next_token.start..next_token.end];
        self.nullifyToken(index + 1);
    }

    // skip meta when squashing text
    const offset: u1 = if (has_meta) 1 else 0;

    // Squash all tokens inside code block into a single `text` element ...
    self.tokens.items[index + offset + 1] = .{
        .element = tokens.Text,
        .start = self.tokens.items[index + offset + 1].start + 1, // + 1 to skip linebreak after ```
        .end = self.tokens.items[end - 1].end,
    };

    // ... and then nullify the squashed tokens
    for (index + offset + 2..end - 1) |token_index| {
        self.nullifyToken(token_index);
    }
}

/// Parse a list into a single node with list item children, of which each list item has a text
/// node as its only child.
fn parseList(
    self: *Ast,
    node: *Node,
    index: usize,
    comptime list_type: enum { ordered, unordered },
) !void {
    var token_index = index;

    while (token_index < self.tokens.items.len) {
        if (token_index + 3 > self.tokens.items.len - 1) {
            break;
        }

        const list_item_type = switch (list_type) {
            .ordered => .ordered_list_item,
            .unordered => .unordered_list_item,
        };
        const expected = &[_]tokens.ElementType{ list_item_type, .text, .linebreak };
        if (!self.expectTokens(token_index, expected)) break;

        const list_item_token = self.tokens.items[token_index];
        const text_token = self.tokens.items[token_index + 1];

        const list_item_node = try self.createNode(.{
            .element = .{ .type = .list_item },
            .start = list_item_token.start,
            .end = list_item_token.end,
        });

        const text_node = try self.createNode(
            .{ .element = tokens.Text, .start = text_token.start, .end = text_token.end },
        );

        try list_item_node.children.append(text_node);
        try node.children.append(list_item_node);
        token_index += expected.len;
    }

    if (token_index > index) {
        const element_type = switch (list_type) {
            .ordered => .ordered_list,
            .unordered => .unordered_list,
        };

        node.token = .{
            .element = .{ .type = element_type },
            .start = self.tokens.items[index].start,
            .end = self.tokens.items[token_index].end,
        };

        for (index + 1..token_index) |nullify_index| self.nullifyToken(nullify_index);
    } else {
        node.token = .{
            .element = tokens.Text,
            .start = self.tokens.items[index].start,
            .end = self.tokens.items[index].end,
        };
    }
}

fn expectTokens(self: Ast, start: usize, expected: []const tokens.ElementType) bool {
    if (start + expected.len >= self.tokens.items.len) return false;

    for (expected, start..) |token_type, index| {
        const actual = self.tokens.items[index].element.type;
        if (actual != token_type) return false;
    }

    return true;
}

/// Nullify a token. Used to prevent close tokens from being included in generated AST.
fn nullifyToken(self: *Ast, index: usize) void {
    self.tokens.replaceRangeAssumeCapacity(index, 1, &[_]tokens.Token{.{
        .element = .{ .type = .none },
        .start = self.tokens.items[index].start,
        .end = self.tokens.items[index].end,
    }});
}

// Create a new node on the heap.
fn createNode(self: Ast, token: tokens.Token) !*Node {
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
