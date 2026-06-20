const std = @import("std");
const zmd = @import("root.zig");

pub fn main(init: std.process.Init) !void {
    var file = try std.Io.Dir.cwd().openFile(init.io, "README.md", .{});
    var buffer: [256]u8 = undefined;
    const stdout: std.Io.File = .stdout();
    var reader = file.reader(init.io, &buffer);

    var buf: [256]u8 = undefined;
    var writer = stdout.writer(init.io, &buf);

    const start: std.Io.Timestamp = .now(init.io, .awake);
    try zmd.parse(&reader.interface, &writer.interface, .{});
    const duration = start.untilNow(init.io, .awake);
    try duration.format(&writer.interface);
    try writer.flush();
}
