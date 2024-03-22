const std = @import("std");
const Node = @import("Node.zig");
const tokens = @import("tokens.zig");

const Parser = @This();

allocator: std.mem.Allocator,
input: []const u8,
tokens: std.ArrayList(tokens.Token),

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

/// Iterate through input, separating into tokens to be fed to the parser.
pub fn tokenize(self: *Parser) !void {
    var index: usize = 0;

    while (index < self.input.len) : (index += 1) {
        if (self.firstToken(index)) |token| {
            try self.tokens.append(token);
            index = token.end;
        } else break;
    }
}

fn firstToken(self: Parser, index: usize) ?tokens.Token {
    for (tokens.elements) |element| {
        if (index + element.syntax.len > self.input.len) continue;
        if (element.clear and (index > 0 and self.input[index - 1] != '\n')) continue;
        if (std.mem.eql(u8, self.input[index..element.syntax.len], element.syntax)) {
            return .{ .element = element, .start = index, .end = index + element.syntax.len };
        }
    }

    if (self.input.len - index < 1) return null;

    var next_token = index + 1;
    while (next_token < self.input.len) : (next_token += 1) {
        for (tokens.elements) |element| {
            if (element.clear and self.input[next_token - 1] != '\n') continue;
            if (std.mem.startsWith(u8, self.input[next_token..], element.syntax)) {
                return .{ .element = tokens.Text, .start = index, .end = next_token };
            }
        }
    }

    return .{ .element = tokens.Text, .start = index, .end = self.input.len };
}
