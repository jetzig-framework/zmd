const std = @import("std");

pub const zmd = @import("src/root.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zmd_mod = b.addModule("zmd", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "zmd",
        .use_llvm = false,
        .root_module = zmd_mod,
    });
    b.installArtifact(lib);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(
        &b.addTest(.{
            .name = "zmd",
            .root_module = zmd_mod,
        }).step,
    );

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(
        &b.addInstallDirectory(.{
            .source_dir = lib.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        }).step,
    );
}
