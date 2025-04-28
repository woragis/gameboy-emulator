const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gameboy-emulator",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("SDL2");

    b.installArtifact(exe);

    // 👇 This allows "zig build run"
    const run_cmd = b.addRunArtifact(exe);
    b.step("run", "Run the emulator").dependOn(&run_cmd.step);
}
