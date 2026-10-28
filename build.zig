const std = @import("std");
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;
const zig = std.zig;
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const Module = Build.Module;
const ResolvedTarget = Build.ResolvedTarget;
const Dependency = Build.Dependency;
const utils = @import("build/utils.zig");

pub const Config = @import("src/Config.zig");

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zmd = b.addModule("zmd", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    utils.addTest(b, "zmd", zmd);

    utils.addBenchmark(b, "zmd", b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }));

    const lib = b.addLibrary(.{
        .name = "zmd",
        .use_llvm = false,
        .root_module = zmd,
    });
    b.installArtifact(lib);

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(
        &b.addInstallDirectory(.{
            .source_dir = lib.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        }).step,
    );
}
