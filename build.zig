const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const benchmark = b.step("benchmark", "Run benchmark");
    benchmark.dependOn(
        &b.addRunArtifact(
            b.addExecutable(.{
                .name = "smoke_test",
                .root_module = b.createModule(.{
                    .root_source_file = b.path("src/main.zig"),
                    .target = target,
                    .optimize = optimize,
                }),
            }),
        ).step,
    );

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

    const unit_tests = b.addTest(.{
        .name = "zmd",
        .root_module = zmd_mod,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(
        &b.addInstallDirectory(.{
            .source_dir = lib.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        }).step,
    );
}
