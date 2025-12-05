// build.zig - Zig's build configuration file
// This is like a Makefile but written in Zig itself!
// Run `zig build` to build all, or `zig build run-day01` to run a specific day

const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options - lets you cross-compile with -Dtarget=...
    const target = b.standardTargetOptions(.{});

    // Standard optimization options - debug by default, use -Doptimize=ReleaseFast for speed
    const optimize = b.standardOptimizeOption(.{});

    // Create an executable for each day
    // inline for is a comptime loop - it unrolls at compile time
    inline for (.{ "day01", "day02", "day03", "day04", "day05" }) |day| {
        // Zig 0.15 changed the API - now we pass root_module instead of root_source_file
        const exe = b.addExecutable(.{
            .name = day,
            .root_module = b.createModule(.{
                .root_source_file = b.path(day ++ "/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Install the executable to zig-out/bin/
        b.installArtifact(exe);

        // Create a run step for this day
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        // Set the working directory to the day's folder so input.txt is found
        run_cmd.setCwd(b.path(day));

        // Create a step like "run-day01" that depends on building + running
        const run_step = b.step("run-" ++ day, "Run " ++ day);
        run_step.dependOn(&run_cmd.step);
    }
}
