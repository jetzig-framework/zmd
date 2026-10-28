const std = @import("std");
const Build = std.Build;
const Step = Build.Step;
const Compile = Step.Compile;
const Run = Step.Run;
const Module = Build.Module;
const Import = Module.Import;

pub fn import(name: []const u8, module: *Module) Import {
    return .{ .name = name, .module = module };
}

pub fn addExe(b: *Build, comptime name: []const u8, module: *Module) void {
    const artifact = makeArtifact(b, name, module);
    getStep(b, .makeExe(name)).dependOn(artifact);
}

pub fn addBenchmark(b: *Build, name: []const u8, module: *Module) void {
    const artifact = makeArtifact(b, name, module);
    getStep(b, .benchmark).dependOn(artifact);
}

pub fn addTest(b: *Build, name: []const u8, module: *Module) void {
    const test_module = b.addTest(.{
        .name = name,
        .root_module = module,
        .filters = testFilters(b),
    });
    const artifact = b.addRunArtifact(test_module);
    getStep(b, .testing).dependOn(&artifact.step);
}

const StepInfo = struct {
    name: []const u8,
    description: []const u8,

    pub fn makeExe(comptime name: []const u8) StepInfo {
        return .{ .name = name, .description = "Build " ++ name };
    }
    pub const testing: StepInfo = .{ .name = "test", .description = "Run tests" };
    pub const benchmark: StepInfo = .{ .name = "benchmark", .description = "Run benchmarks" };
};

fn makeArtifact(b: *Build, name: []const u8, module: *Module) *Step {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = module,
    });
    return &b.addRunArtifact(exe).step;
}

fn getStep(b: *Build, step_info: StepInfo) *Step {
    return if (b.top_level_steps.get(step_info.name)) |tls|
        &tls.step
    else
        b.step(step_info.name, step_info.description);
}

fn testFilters(b: *Build) []const []const u8 {
    if (!b.available_options_map.contains("test-filter")) return b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &.{};

    const opt = b.user_input_options.getPtr("test-filter") orelse return &.{};
    return switch (opt.*) {
        .list => |l| l.items,
        .scalar => |s| b.allocator.dupe([]const u8, &.{s}) catch @panic("OOM"),
        else => &.{},
    };
}
