const Parser = @This();

reader: *Reader,
writer: *Writer,
config: Config,
levels: [max_list_depth]Level = undefined,
depth: usize = 0,

pub fn run(self: *Parser) !void {
    const root_close = try self.config.root(self.writer, .{});

    while (try self.nextLine()) |raw| {
        const line = stripNewline(raw);
        const body = std.mem.trimStart(u8, line, &whitespace);

        if (body.len == 0) {
            try self.closeAllLists();
            continue;
        }

        if (std.mem.startsWith(u8, body, "```")) {
            try self.closeAllLists();
            try self.renderBlock(std.mem.trim(u8, body[3..], &whitespace));
            continue;
        }

        if (headingLevel(body)) |level| {
            try self.closeAllLists();
            try self.renderHeading(level, std.mem.trim(u8, body[level..], &whitespace));
            continue;
        }

        if (listItem(body)) |item| {
            try self.processListItem(line.len - body.len, item);
            continue;
        }

        try self.closeAllLists();
        try self.render(.paragraph, line);
    }

    try self.closeAllLists();
    if (root_close.len > 0) try self.writer.writeAll(root_close);
    try self.writer.flush();
}

fn nextLine(self: *Parser) !?[]const u8 {
    const line = self.reader.peekDelimiterInclusive('\n') catch |err|
        switch (err) {
            error.EndOfStream => {
                const n = self.reader.bufferedLen();
                if (n == 0) return null;
                return try self.reader.take(n);
            },
            else => return err,
        };
    self.reader.toss(line.len);
    return line;
}

fn render(
    self: *Parser,
    comptime element: ElementType,
    content: []const u8,
) !void {
    const formatter: Config.Fn = @field(self.config, @tagName(element));
    const close = try formatter(self.writer, .{});
    try self.renderInline(content);
    if (close.len > 0) try self.writer.writeAll(close);
}

fn renderHeading(self: *Parser, level: usize, content: []const u8) !void {
    const formatter = switch (level) {
        1 => self.config.h1,
        2 => self.config.h2,
        3 => self.config.h3,
        4 => self.config.h4,
        5 => self.config.h5,
        else => self.config.h6,
    };
    const close = try formatter(self.writer, .{});
    try self.renderInline(content);
    if (close.len > 0) try self.writer.writeAll(close);
}

fn renderBlock(self: *Parser, meta: []const u8) !void {
    const node_value: Node = .{ .meta = if (meta.len > 0) meta else null };
    const close = try self.config.block(self.writer, node_value);

    var started = false;
    while (try self.nextLine()) |raw| {
        const line = stripNewline(raw);
        if (std.mem.eql(u8, std.mem.trim(u8, line, &whitespace), "```")) break;
        if (started) {
            try self.writer.writeByte('\n');
            try writeEscaped(self.writer, line);
            continue;
        }
        const lead = std.mem.trimStart(u8, line, &whitespace);
        if (lead.len == 0) continue;
        try writeEscaped(self.writer, lead);
        started = true;
    }
    if (close.len > 0) try self.writer.writeAll(close);
}

fn processListItem(self: *Parser, indent: usize, item: ListMatch) !void {
    while (self.depth > 0 and indent < self.levels[self.depth - 1].indent) {
        try self.closeTopItem();
        try self.closeTopList();
    }

    if (self.depth == 0 or
        (indent > self.levels[self.depth - 1].indent and self.depth < max_list_depth))
    {
        if (self.depth > 0) {
            self.levels[self.depth - 1].has_children = true;
            try self.writer.writeByte('\n');
        }
        try self.pushList(item.kind, indent);
    } else try self.closeTopItem();

    try self.writeItem(std.mem.trimStart(u8, item.content, &whitespace));
}

fn pushList(self: *Parser, kind: ListKind, indent: usize) !void {
    const d = self.depth;
    try self.writeIndent(4 * d);
    const formatter: Config.Fn = switch (kind) {
        .ordered => self.config.ordered_list,
        .unordered => self.config.unordered_list,
    };
    self.levels[d] = .{
        .indent = indent,
        .kind = kind,
        .list_close = try formatter(self.writer, .{}),
        .item_close = "",
        .item_open = false,
        .has_children = false,
    };
    self.depth = d + 1;
}

fn writeItem(self: *Parser, content: []const u8) !void {
    const d = self.depth - 1;
    try self.writeIndent(4 * d);
    const item_close = try self.config.list_item(self.writer, .{});
    try self.renderInline(content);
    self.levels[d].item_close = item_close;
    self.levels[d].item_open = true;
    self.levels[d].has_children = false;
}

fn closeTopItem(self: *Parser) !void {
    const d = self.depth - 1;
    const lvl = &self.levels[d];
    if (!lvl.item_open) return;
    if (lvl.has_children) try self.writeIndent(4 * d + 2);
    if (lvl.item_close.len > 0) try self.writer.writeAll(lvl.item_close);
    lvl.item_open = false;
}

fn closeTopList(self: *Parser) !void {
    const d = self.depth - 1;
    try self.writeIndent(4 * d);
    if (self.levels[d].list_close.len > 0)
        try self.writer.writeAll(self.levels[d].list_close);
    self.depth = d;
}

fn closeAllLists(self: *Parser) !void {
    while (self.depth > 0) {
        try self.closeTopItem();
        try self.closeTopList();
    }
}

fn writeIndent(self: *Parser, spaces: usize) !void {
    const pad = " " ** 32;
    var n = spaces;
    while (n > 0) {
        const chunk = @min(n, pad.len);
        try self.writer.writeAll(pad[0..chunk]);
        n -= chunk;
    }
}

fn renderInline(self: *Parser, s: []const u8) anyerror!void {
    var i: usize = 0;
    var text_start: usize = 0;

    while (i < s.len) {
        const pending = s[text_start..i];
        const consumed: ?usize = switch (s[i]) {
            '`' => try self.inlineDelimited(s, i, pending, "`", .code, false),
            '!' => if (startsAt(s, i + 1, "[")) try self.inlineLink(s, i, pending, .image) else null,
            '[' => try self.inlineLink(s, i, pending, .link),
            '{' => if (startsAt(s, i + 1, "{")) try self.inlineRef(s, i, pending) else null,
            '*' => if (startsAt(s, i, "**"))
                try self.inlineDelimited(s, i, pending, "**", .bold, true)
            else
                try self.inlineDelimited(s, i, pending, "*", .italic, true),
            '_' => if (startsAt(s, i, "__"))
                try self.inlineDelimited(s, i, pending, "__", .bold, true)
            else
                try self.inlineDelimited(s, i, pending, "_", .italic, true),
            else => null,
        };

        if (consumed) |end| {
            i = end;
            text_start = end;
        } else i += 1;
    }
    if (text_start < s.len) try writeEscaped(self.writer, s[text_start..]);
}

fn inlineDelimited(
    self: *Parser,
    s: []const u8,
    open: usize,
    pending: []const u8,
    comptime syntax: []const u8,
    comptime element: ElementType,
    comptime recurse: bool,
) !?usize {
    const inner_start = open + syntax.len;
    const close = std.mem.indexOfPos(u8, s, inner_start, syntax) orelse
        return null;
    try writeEscaped(self.writer, pending);
    const formatter: Config.Fn = @field(self.config, @tagName(element));
    const close_tag = try formatter(self.writer, .{});
    if (recurse)
        try self.renderInline(s[inner_start..close])
    else
        try writeEscaped(self.writer, s[inner_start..close]);
    if (close_tag.len > 0) try self.writer.writeAll(close_tag);
    return close + syntax.len;
}

fn inlineRef(
    self: *Parser,
    s: []const u8,
    open: usize,
    pending: []const u8,
) !?usize {
    const inner_start = open + 2;
    const close = std.mem.indexOfPos(u8, s, inner_start, "}}") orelse
        return null;
    try writeEscaped(self.writer, pending);
    const close_tag = try self.config.ref(self.writer, .{});
    try self.writer.writeAll(s[inner_start..close]);
    if (close_tag.len > 0) try self.writer.writeAll(close_tag);
    return close + 2;
}

fn inlineLink(
    self: *Parser,
    s: []const u8,
    open: usize,
    pending: []const u8,
    comptime kind: ElementType,
) !?usize {
    const bracket = if (kind == .image) open + 1 else open;
    const title_close = findBracketClose(s, bracket) orelse return null;
    const paren_open = title_close + 1;
    if (paren_open >= s.len or s[paren_open] != '(') return null;
    const paren_close = findParenClose(s, paren_open) orelse return null;

    try writeEscaped(self.writer, pending);
    const node_value: Node = .{ .href = s[paren_open + 1 .. paren_close] };
    const formatter: Config.Fn = if (kind == .image) self.config.image else self.config.link;
    const close_tag = try formatter(self.writer, node_value);
    try self.renderInline(s[bracket + 1 .. title_close]);
    if (close_tag.len > 0) try self.writer.writeAll(close_tag);
    return paren_close + 1;
}

fn stripNewline(line: []const u8) []const u8 {
    if (line.len > 0 and line[line.len - 1] == '\n') return line[0 .. line.len - 1];
    return line;
}

fn startsAt(s: []const u8, index: usize, needle: []const u8) bool {
    return index < s.len and std.mem.startsWith(u8, s[index..], needle);
}

fn headingLevel(body: []const u8) ?usize {
    var level: usize = 0;
    while (level < body.len and level < 6 and body[level] == '#') : (level += 1) {}
    if (level == 0) return null;
    if (level < body.len and body[level] != ' ') return null;
    return level;
}

const ListMatch = struct { kind: Parser.ListKind, content: []const u8 };

fn listItem(body: []const u8) ?ListMatch {
    if (body.len >= 2 and body[1] == ' ') {
        switch (body[0]) {
            '*', '+', '-' => return .{ .kind = .unordered, .content = body[2..] },
            else => {},
        }
    }
    if (std.ascii.isDigit(body[0])) {
        var end: usize = 1;
        while (end < body.len and std.ascii.isDigit(body[end])) : (end += 1) {}
        if (end + 1 < body.len and body[end] == '.' and body[end + 1] == ' ')
            return .{ .kind = .ordered, .content = body[end + 2 ..] };
    }
    return null;
}

fn findBracketClose(s: []const u8, open: usize) ?usize {
    var depth: usize = 0;
    var i = open + 1;
    while (i < s.len) : (i += 1) {
        switch (s[i]) {
            '[' => depth += 1,
            ']' => {
                if (depth == 0) return i;
                depth -= 1;
            },
            else => {},
        }
    }
    return null;
}

fn findParenClose(s: []const u8, open: usize) ?usize {
    var depth: usize = 0;
    var i = open + 1;
    while (i < s.len) : (i += 1) {
        switch (s[i]) {
            '(' => depth += 1,
            ')' => {
                if (depth == 0) return i;
                depth -= 1;
            },
            else => {},
        }
    }
    return null;
}

fn writeEscaped(writer: *Writer, input: []const u8) Writer.Error!void {
    var start: usize = 0;
    for (input, 0..) |byte, i| {
        const replacement: ?[]const u8 = switch (byte) {
            '&' => "&amp;",
            '<' => "&lt;",
            '>' => "&gt;",
            '\r' => "",
            else => null,
        };
        if (replacement) |r| {
            if (i > start) try writer.writeAll(input[start..i]);
            try writer.writeAll(r);
            start = i + 1;
        }
    }
    if (start < input.len) try writer.writeAll(input[start..]);
}

const std = @import("std");
const Reader = std.Io.Reader;
const Writer = std.Io.Writer;
const Config = @import("Config.zig");
const whitespace = std.ascii.whitespace;
const tokens = @import("tokens.zig");
const ElementType = tokens.ElementType;
pub const Node = struct {
    meta: ?[]const u8 = null,
    href: ?[]const u8 = null,
};

const max_list_depth = 16;
const ListKind = enum { unordered, ordered };
const Level = struct {
    indent: usize,
    kind: ListKind,
    list_close: []const u8,
    item_close: []const u8,
    item_open: bool,
    has_children: bool,
};
