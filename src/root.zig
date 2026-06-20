const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Writer = Io.Writer;
const Reader = Io.Reader;
const File = Io.File;
const Parser = @import("Parser.zig");

pub const Config = @import("Config.zig");

pub fn parse(reader: *Reader, writer: *Writer, config: Config) !void {
    var parser: Parser = .{
        .reader = reader,
        .writer = writer,
        .config = config,
    };
    try parser.run();
}

pub fn parseSlice(slice: []const u8, writer: *Writer, config: Config) !void {
    var reader: Reader = .fixed(slice);
    try parse(&reader, writer, config);
}

pub fn parseAlloc(allocator: Allocator, input: []const u8, config: Config) ![]u8 {
    var reader: Reader = .fixed(input);
    var aw: Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try parse(&reader, &aw.writer, config);
    return aw.toOwnedSlice();
}

pub fn parseFile(reader: File.Reader, writer: *Writer, config: Config) !void {
    try parse(&reader.interface, writer, config);
}

pub fn parseFileAlloc(allocator: Allocator, reader: File.Reader, config: Config) ![]u8 {
    var aw: Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try parse(&reader.interface, &aw.writer, config);
    return aw.toOwnedSlice();
}

test {
    _ = @import("tests/general.zig");
    _ = @import("tests/elements.zig");
}
