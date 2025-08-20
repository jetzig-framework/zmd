const std = @import("std");
const Node = @import("Node.zig");
const tokens = @import("tokens.zig");
const Allocator = std.mem.Allocator;
const Ast = @This();
const ArrayList = std.ArrayList;

input: []const u8,
tokens_list: ArrayList(tokens.Token),
state: enum { initial, tokenized, parsed } = .initial,
current_node: *Node = undefined,
/// Used to optimize tokenization: the last `isCleared()` result
last_cleared: struct { index: usize, cleared: bool } = .{
    .index = 0,
    .cleared = true,
},
visited: std.AutoHashMap(usize, bool) = undefined,
elements_map: std.AutoHashMap(tokens.ElementType, tokens.Element) = undefined,
debug: bool = false,
node_registry: ArrayList(*Node) = undefined,

/// Initialize a new Ast.
pub fn init(allocator: Allocator, input: []const u8) !Ast {
    return .{
        .input = input,
        .tokens_list = try .initCapacity(allocator, 1),
        .node_registry = try .initCapacity(allocator, 1),
    };
}

/// Deinitialize and free allocated memory.
pub fn deinit(self: *Ast, allocator: Allocator) void {
    self.tokens_list.deinit(allocator);
    self.elements_map.deinit();
    self.visited.deinit();
    for (self.node_registry.items) |node| {
        node.children.deinit(allocator);
        allocator.destroy(node);
    }
    self.node_registry.deinit(allocator);
    self.* = undefined;
}

/// Parse tokenized input. Must call `tokenize()` first.
pub fn parse(self: *Ast, allocator: Allocator) !*Node {
    if (self.state != .tokenized) unreachable;

    const root = try self.createNode(
        allocator,
        .{ .element = tokens.Root, .start = 0, .end = self.input.len },
    );

    self.visited = .init(allocator);

    _ = try self.parseChildNodes(allocator, 0, root);

    if (self.debug) debugTree(root, 0);

    self.state = .parsed;

    return root;
}

/// Iterate through input, separating into tokens to be fed to the parser.
pub fn tokenize(self: *Ast, allocator: Allocator) !void {
    if (self.state != .initial) unreachable;

    self.elements_map = .init(allocator);

    for (tokens.elements) |element| {
        try self.elements_map.put(element.type, element);
    }

    var index: usize = 0;

    var previous_token: ?tokens.Token = null;

    try self.tokens_list.append(
        allocator,
        .{ .element = tokens.Root, .start = 0, .end = 0 },
    );

    while (index < self.input.len) {
        if (self.firstToken(previous_token, index)) |token| {
            const cleared = self.isCleared(index);
            if (previous_token) |previous|
                try self.maybeTokenizeText(
                    allocator,
                    previous,
                    token,
                    cleared,
                );

            if (self.isEmptyLine(index) and
                !token.element.clear and
                token.element.type != .linebreak)
                try self.appendParagraph(allocator, index);

            try self.tokens_list.append(allocator, token);
            previous_token = token;

            // Prepend a text token if the first token (after the root token)
            // does not start at the beginning of the input.
            if (self.tokens_list.items.len == 2 and
                self.tokens_list.items[1].start > 0)
            {
                const token_start = self.tokens_list.items[1].start;
                const text_end = if (cleared and token.element.clear)
                    std.mem.lastIndexOfNone(
                        u8,
                        self.input[0..token_start],
                        &std.ascii.whitespace,
                    ) orelse 0
                else
                    self.tokens_list.items[1].start;

                if (0 != text_end) try self.insertText(
                    allocator,
                    1,
                    0,
                    text_end,
                );
            }
            index = token.end;
        } else index += 1;
    }

    if (self.tokens_list.items.len > 0) {
        const last_token = self.tokens_list.items[self.tokens_list.items.len - 1];
        // Append a text node for the remainder of the buffer if present:
        if (last_token.end < self.input.len - 1) {
            try self.appendText(
                allocator,
                last_token.end,
                self.input.len,
            );
        }
    }

    try self.tokens_list.append(
        allocator,
        .{
            .element = .{ .type = .eof },
            .start = self.input.len,
            .end = self.input.len,
        },
    );

    if (self.debug) {
        for (self.tokens_list.items) |token| self.debugToken(
            allocator,
            token,
        );
    }

    self.state = .tokenized;
}

// Detect if a given input index proceeds a linebreak (possibly with trailing
// whitespace), or if the cursor is at first character in the input.
fn isCleared(self: *Ast, index: usize) bool {
    if (index == 0) return true;

    // It's assumed that `index` is always increasing
    std.debug.assert(index >= self.last_cleared.index);

    var cursor = index;
    while (cursor > self.last_cleared.index) {
        cursor -= 1;
        if (self.input[cursor] == '\n') {
            self.last_cleared = .{
                .index = index,
                .cleared = true,
            };
            return true;
        }
        if (!std.ascii.isWhitespace(self.input[cursor])) {
            self.last_cleared = .{
                .index = index,
                .cleared = false,
            };
            return false;
        }
    }

    self.last_cleared.index = index;
    return self.last_cleared.cleared;
}

// True if current character is a blank line or BOF
fn isEmptyLine(self: Ast, index: usize) bool {
    return index == 0 or self.input[index - 1] == '\n';
}

// Return the first token in the input from the given index.
fn firstToken(self: *Ast, previous_token: ?tokens.Token, index: usize) ?tokens.Token {
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

    const index_clear = self.isCleared(index);
    for (tokens.elements) |element| {
        if (index + element.syntax.len > self.input.len) continue;
        const matched = std.mem.startsWith(u8, self.input[index..], element.syntax);
        const matched_after = matched and self.matchAfter(element, index);
        const matched_close = matched_after and self.matchClose(element);
        const matched_clear = matched_close and !element.clear or (element.clear and index_clear);

        if (matched and matched_after and matched_close and matched_clear) {
            const token: tokens.Token = .{
                .element = element,
                .start = index,
                .end = index + element.syntax.len,
            };
            return token;
        }
    }

    return null;
}

// Verify that a token immediately proceeds another token if `.after` property
// is set (otherwise we treat as text).
fn matchAfter(self: Ast, element: tokens.Element, index: usize) bool {
    const after_element_type = element.after orelse return true;

    // Allow a crash on null - it is a bug (we add all elements to map on start)
    const after_element = self.elements_map.get(after_element_type).?;

    if (index < after_element.syntax.len) return false;
    const actual = self.input[index - after_element.syntax.len .. index];
    return std.mem.eql(u8, after_element.syntax, actual);
}

// Verify that a closing token has a previously-opened token in the stack
// (otherwise we treat as text).
fn matchClose(self: Ast, element: tokens.Element) bool {
    if (element.expect == null) return true;
    if (self.tokens_list.items.len == 0) return false;

    var index: usize = self.tokens_list.items.len - 1;
    while (index > 0) : (index -= 1) {
        switch (self.tokens_list.items[index].element.type) {
            .text, .linebreak, .italic => continue,
            else => return self.tokens_list.items[index].element.type == element.expect,
        }
    }
    return false;
}

// Recursively build a tree of nodes from the given token index and a provided
// root node.
fn parseChildNodes(
    self: *Ast,
    allocator: Allocator,
    start: usize,
    node: *Node,
) error{OutOfMemory}!bool {
    if (try self.visited.fetchPut(start, true)) |_| return false;
    var index = start;
    const end = self.getCloseIndex(index) orelse index;
    while (index < end) {
        index += 1;
        const child_node = try self.createNode(
            allocator,
            self.tokens_list.items[index],
        );
        switch (child_node.token.element.type) {
            .link_title => self.parseLink(child_node, index, .link),
            .image_title => self.parseLink(child_node, index, .image),
            .block, .code => self.parseBlock(child_node, index),
            .unordered_list_item => try self.parseList(
                allocator,
                node,
                child_node,
                index,
                .unordered,
            ),
            .ordered_list_item => try self.parseList(
                allocator,
                node,
                child_node,
                index,
                .ordered,
            ),
            .text => try self.parseText(allocator, child_node),
            else => {},
        }
        self.nullifyToken(end);
        if (index >= self.tokens_list.items.len - 1) break;
        if (try self.parseChildNodes(allocator, index, child_node)) {
            if (child_node.token.element.type != .none)
                try node.children.append(allocator, child_node);
        }
    }
    return true;
}

/// Locate the token index for the syntax that closes the current token.
fn getCloseIndex(self: Ast, start: usize) ?usize {
    if (start >= self.tokens_list.items.len - 1) return null;
    const match_token = self.tokens_list.items[start];
    if (match_token.element.close == .none) return null;

    for (self.tokens_list.items[start + 1 ..], 1..) |token, index| {
        if (token.element.type == match_token.element.close)
            return index + start;
    }

    return null;
}

// Convert text into a paragraph if it proceeds a linebreak or the root node,
// otherwise add plain text (text is the generic token for anything that does
// not match another token type, e.g. `# Foo` is comprised of a `.h1` and a
// `.text` token).
fn maybeTokenizeText(
    self: *Ast,
    allocator: Allocator,
    prev_token: tokens.Token,
    token: tokens.Token,
    cleared: bool,
) !void {
    if (prev_token.end >= token.start) return;

    switch (prev_token.element.type) {
        .code, .block => return,
        else => {},
    }

    const cleared_token = cleared and token.element.clear;

    if ((prev_token.element.type == .linebreak or
        prev_token.element.type == .root) and
        !cleared_token)
    {
        try self.tokens_list.append(
            allocator,
            .{
                .element = tokens.Paragraph,
                .start = token.start,
                .end = token.end,
            },
        );
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
                try self.appendText(allocator, prev_token.end, token.start);
                break;
            }
        }
    } else {
        try self.appendText(allocator, prev_token.end, token.start);
    }
}

// Appande a paragraph token at the end of the tokens array.
fn appendParagraph(self: *Ast, allocator: Allocator, index: usize) !void {
    try self.tokens_list.append(
        allocator,
        .{ .element = tokens.Paragraph, .start = index, .end = index },
    );
}
// Append a text token to the end of the tokens array.
fn appendText(self: *Ast, allocator: Allocator, start: usize, end: usize) !void {
    try self.tokens_list.append(
        allocator,
        .{ .element = tokens.Text, .start = start, .end = end },
    );
}

// Insert a text token at the given index.
fn insertText(self: *Ast, allocator: Allocator, index: usize, start: usize, end: usize) !void {
    try self.tokens_list.insert(
        allocator,
        index,
        .{ .element = tokens.Paragraph, .start = start, .end = end },
    );

    try self.tokens_list.insert(
        allocator,
        index + 1,
        .{ .element = tokens.Text, .start = start, .end = end },
    );
}

fn parseText(
    self: *Ast,
    allocator: Allocator,
    node: *Node,
) !void {
    const input = self.input[node.token.start..node.token.end];
    var cursor: usize = 0;
    var text_start: usize = 0;

    while (cursor < input.len) {
        for (tokens.formatters) |element| {
            if (std.mem.startsWith(u8, input[cursor..], element.syntax)) {
                const offset = cursor + element.syntax.len;
                if (std.mem.indexOf(u8, input[offset..], element.syntax)) |end_index| {
                    const pre_text_node = try self.createNode(
                        allocator,
                        .{
                            .element = tokens.Text,
                            .start = node.token.start + text_start,
                            .end = node.token.start + cursor,
                        },
                    );

                    try node.children.append(allocator, pre_text_node);

                    const child_node = try self.createNode(
                        allocator,
                        .{
                            .element = element,
                            .start = node.token.start + cursor,
                            .end = node.token.start + offset + end_index + element.syntax.len,
                        },
                    );

                    try node.children.append(allocator, child_node);

                    const text_node = try self.createNode(
                        allocator,
                        .{
                            .element = tokens.Text,
                            .start = child_node.token.start + element.syntax.len,
                            .end = child_node.token.end - element.syntax.len,
                        },
                    );

                    try child_node.children.append(allocator, text_node);
                    cursor = offset + end_index + element.syntax.len;
                    text_start = cursor;
                    continue;
                }
            }
        }
        cursor += 1;
    }
    if (node.children.items.len > 0) {
        const last_child = node.children.items[node.children.items.len - 1];
        if (last_child.token.end < node.token.end) {
            const remainder_node = try self.createNode(
                allocator,
                .{
                    .element = tokens.Text,
                    .start = last_child.token.end,
                    .end = node.token.end,
                },
            );
            try node.children.append(allocator, remainder_node);
        }
        node.token = .{
            .element = tokens.Text,
            .start = node.token.start,
            .end = node.token.start,
        };
    }
}

// Translate a link/image title and href into a single node. Nullify dangling
// nodes.
fn parseLink(
    self: *Ast,
    node: *Node,
    index: usize,
    link_type: enum { image, link },
) void {
    const expected_tokens = &[_]tokens.ElementType{
        .text,
        .title_close,
        .href,
        .text,
        .href_close,
    };
    if (index + expected_tokens.len + 1 >= self.tokens_list.items.len - 1)
        return self.swapText(node, index);

    for (expected_tokens, index + 1..) |expected, offset|
        if (self.tokens_list.items[offset].element.type != expected)
            return self.swapText(node, index);

    const start = node.token.start;
    const end = self.tokens_list.items[index + expected_tokens.len + 1].end;

    const element_type: tokens.ElementType = switch (link_type) {
        .image => .image,
        .link => .link,
    };

    node.token = .{ .element = .{ .type = element_type }, .start = start, .end = end };
    node.href = self.input[self.tokens_list.items[index + 4].start..self.tokens_list.items[index + 4].end];
    node.title = self.input[self.tokens_list.items[index + 1].start..self.tokens_list.items[index + 1].end];

    for (0..expected_tokens.len) |offset|
        self.nullifyToken(index + offset);
}

// Swap a given node with a plain text node. Used when a link/image token does
// not have the expected subsequent tokens to build a full link/image node.
fn swapText(self: Ast, node: *Node, index: usize) void {
    const token = self.tokens_list.items[index];
    node.token = .{
        .element = tokens.Text,
        .start = token.start,
        .end = token.end,
    };
}

// Parse a `block` or `code` element. Set raw content on node so it can be
// written out directly (i.e. any other tokens within the code/block element are
// ignored). Add `meta` to `block` node if present (`node.meta` will be "zig"
// for ```zig code blocks).
fn parseBlock(self: *Ast, node: *Node, index: usize) void {
    const token = self.tokens_list.items[index];
    const close_token = if (self.getCloseIndex(index)) |close|
        self.tokens_list.items[close]
    else
        return;
    const content = self.input[node.token.start + node.token.element.syntax.len .. close_token.start];
    const has_meta = token.element.type == .block and !std.mem.startsWith(u8, content, "\n");

    // meta is the "zig" in ```zig
    if (has_meta) {
        if (std.mem.indexOfScalar(u8, content, '\n')) |linebreak_index| {
            node.meta = content[0..linebreak_index];
            node.content = strip(content[linebreak_index..]);
        }
    } else node.content = strip(content);
}

/// Parse a list into a single node with list item children, of which each list item has a text
/// node as its only child.
fn parseList(
    self: *Ast,
    allocator: Allocator,
    parent_node: *Node,
    node: *Node,
    index: usize,
    comptime list_type: enum { ordered, unordered },
) !void {
    var token_index = index;

    while (token_index < self.tokens_list.items.len) {
        const list_item_close_index = self.getCloseIndex(token_index) orelse break;
        const list_item_token = self.tokens_list.items[token_index];

        const list_item_node = try self.createNode(allocator, .{
            .element = .{ .type = .list_item },
            .start = list_item_token.start,
            .end = list_item_token.end,
        });
        try node.children.append(allocator, list_item_node);

        _ = try self.parseChildNodes(allocator, token_index, list_item_node);

        token_index = list_item_close_index + 1;
    }

    if (token_index > index) {
        const element_type = switch (list_type) {
            .ordered => .ordered_list,
            .unordered => .unordered_list,
        };

        node.token = .{
            .element = .{ .type = element_type },
            .start = self.tokens_list.items[index].start,
            .end = self.tokens_list.items[token_index].end,
        };

        try parent_node.children.append(allocator, node);

        for (index + 1..token_index) |nullify_index| self.nullifyToken(nullify_index);
    } else {
        node.token = .{
            .element = tokens.Text,
            .start = self.tokens_list.items[index].start,
            .end = self.tokens_list.items[index].end,
        };
    }
}

fn expectTokens(self: Ast, start: usize, expected: []const tokens.ElementType) bool {
    if (start + expected.len >= self.tokens_list.items.len)
        return false;

    for (expected, start..) |token_type, index| {
        const actual = self.tokens_list.items[index].element.type;
        if (actual != token_type) return false;
    }

    return true;
}

/// Nullify a token. Used to prevent close tokens from being included in generated AST.
fn nullifyToken(self: *Ast, index: usize) void {
    self.tokens_list.replaceRangeAssumeCapacity(
        index,
        1,
        &[_]tokens.Token{.{
            .element = .{ .type = .none },
            .start = self.tokens_list.items[index].start,
            .end = self.tokens_list.items[index].end,
        }},
    );
}

// Create a new node on the heap.
fn createNode(self: *Ast, allocator: Allocator, token: tokens.Token) !*Node {
    const node = try allocator.create(Node);
    node.* = .{
        .token = token,
        .children = try .initCapacity(allocator, 1),
    };
    try self.node_registry.append(allocator, node);
    return node;
}

inline fn strip(input: []const u8) []const u8 {
    return std.mem.trim(u8, input, &std.ascii.whitespace);
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
fn debugToken(self: Ast, allocator: Allocator, token: tokens.Token) void {
    var buf = std.ArrayList(u8).initCapacity(allocator, 1) catch @panic("asdf");
    defer buf.deinit(allocator);
    var writer = buf.writer(allocator).adaptToNewApi(&.{}).new_interface;
    writer.writeByte('"') catch @panic("OOM");
    std.zig.stringEscape(self.input[token.start..token.end], &writer) catch @panic("OOM");
    writer.writeByte('"') catch @panic("OOM");
    std.debug.print("[{s}] {s}\n", .{ @tagName(token.element.type), buf.items });
}
