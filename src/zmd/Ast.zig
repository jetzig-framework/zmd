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

    // debugTree(root, 0);

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
        if (self.firstToken(previous_token, index)) |token| {
            const cleared = self.isCleared(index);
            if (previous_token) |previous| try self.maybeTokenizeText(previous, token, cleared);

            if (self.isEmptyLine(index) and
                !token.element.clear and
                token.element.type != .linebreak) try self.appendParagraph(index);

            if (!token.element.clear or (token.element.clear and cleared)) {
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

    // for (self.tokens.items) |token| self.debugToken(token);

    self.state = .tokenized;
}

// Detect if a given input index proceeds a linebreak (possibly with trailing whitespace), or if
// the cursor is at first character in the input.
fn isCleared(self: Ast, index: usize) bool {
    if (index == 0) return true;
    var cursor = index - 1;
    while (cursor > 0) : (cursor -= 1) {
        if (self.input[cursor] == '\n') return true;
        if (!std.ascii.isWhitespace(self.input[cursor])) return false;
    }

    return true; // We made it to the start of the input which counts as cleared.
}

// True if current character is a blank line or BOF
fn isEmptyLine(self: Ast, index: usize) bool {
    return index == 0 or self.input[index - 1] == '\n';
}

// Return the first token in the input from the given index.
fn firstToken(self: Ast, previous_token: ?tokens.Token, index: usize) ?tokens.Token {
    if (previous_token) |previous| {
        if (tokens.toggles.get(@tagName(previous.element.type))) |toggle| {
            const offset = previous.start + previous.element.syntax.len;
            if (std.mem.indexOf(u8, self.input[offset..], toggle.syntax)) |toggle_index| {
                return .{
                    .element = toggle,
                    .start = offset + toggle_index,
                    .end = offset + toggle_index + toggle.syntax.len,
                };
            }
        }
    }

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
fn parseChildNodes(self: *Ast, start: usize, node: *Node) error{OutOfMemory}!bool {
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
            .unordered_list_item => try self.parseList(node, child_node, index, .unordered),
            .ordered_list_item => try self.parseList(node, child_node, index, .ordered),
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
// e.g. `# Foo` is comprised of a `.h1` and a `.text` token).
fn maybeTokenizeText(self: *Ast, prev_token: tokens.Token, token: tokens.Token, cleared: bool) !void {
    if (prev_token.end >= token.start) return;

    const cleared_token = cleared and token.element.clear;

    if ((prev_token.element.type == .linebreak or prev_token.element.type == .root) and !cleared_token) {
        try self.tokens.append(.{
            .element = tokens.Paragraph,
            .start = token.start,
            .end = token.end,
        });
    }

    if (cleared_token) {
        // Only append a text token if the cleared token is not preceded on the same line
        // exclusively by whitespace.
        // This allows indenting cleared tokens, e.g.:
        // ```
        //    * foo
        //    * bar
        //    * baz
        // ```
        // The whitespace before each item will not be injected as a text token.
        for (self.input[prev_token.end + 1 .. token.start]) |char| {
            if (!std.ascii.isWhitespace(char)) {
                try self.appendText(prev_token.end, token.start);
                break;
            }
        }
    } else {
        try self.appendText(prev_token.end, token.start);
    }
}

// Appande a paragraph token at the end of the tokens array.
fn appendParagraph(self: *Ast, index: usize) !void {
    try self.tokens.append(.{
        .element = tokens.Paragraph,
        .start = index,
        .end = index,
    });
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
    if (maybe_end == null) return; // We don't have a closing ``` so don't try to parse
    if (index + 2 >= self.tokens.items.len) return;

    const next_token = self.tokens.items[index + 1];
    const has_meta = !std.mem.startsWith(u8, self.input[next_token.start..next_token.end], "\n");

    // meta is the "zig" in ```zig
    if (has_meta) {
        if (std.mem.indexOfScalar(u8, self.input[next_token.start..next_token.end], '\n')) |linebreak_index| {
            node.meta = self.input[next_token.start .. next_token.start + linebreak_index];
            node.content = self.input[next_token.start + linebreak_index + 1 .. next_token.end];
            self.tokens.items[index + 1] = .{
                .element = next_token.element,
                .start = next_token.start + linebreak_index + 1,
                .end = next_token.end - 1,
            };
        }
    } else {
        self.tokens.items[index + 1] = .{
            .element = next_token.element,
            .start = next_token.start + 1,
            .end = next_token.end - 1,
        };
    }
}

/// Parse a list into a single node with list item children, of which each list item has a text
/// node as its only child.
fn parseList(
    self: *Ast,
    parent_node: *Node,
    node: *Node,
    index: usize,
    comptime list_type: enum { ordered, unordered },
) !void {
    var token_index = index;

    while (token_index < self.tokens.items.len) {
        const list_item_close_index = self.getCloseIndex(token_index) orelse break;
        const list_item_token = self.tokens.items[token_index];

        const list_item_node = try self.createNode(.{
            .element = .{ .type = .list_item },
            .start = list_item_token.start,
            .end = list_item_token.end,
        });
        try node.children.append(list_item_node);

        _ = try self.parseChildNodes(token_index, list_item_node);

        token_index = list_item_close_index + 1;
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

        try parent_node.children.append(node);

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
    if (level == 0) {
        std.debug.print("tree:\n", .{});
    }
    for (0..level + 1) |_| std.debug.print(" ", .{});
    std.debug.print("{s}\n", .{@tagName(node.token.element.type)});
    for (node.children.items) |child_node| {
        debugTree(child_node, level + 1);
    }
}

// Output the type and content of a token
fn debugToken(self: Ast, token: tokens.Token) void {
    var buf = std.ArrayList(u8).init(self.allocator);
    defer buf.deinit();
    const writer = buf.writer();
    writer.writeByte('"') catch @panic("OOM");
    std.zig.stringEscape(self.input[token.start..token.end], "", .{}, writer) catch @panic("OOM");
    writer.writeByte('"') catch @panic("OOM");
    std.debug.print("[{s}] {s}\n", .{ @tagName(token.element.type), buf.items });
}
