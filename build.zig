// build.zig - Zig's build configuration file
// This is like a Makefile but written in Zig itself!
// Run `zig build` to build all, or `zig build run-day01` to run a specific day

const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options - lets you cross-compile with -Dtarget=...
    const target = b.standardTargetOptions(.{});

    // Standard optimization options - debug by default, use -Doptimize=ReleaseFast for speed
    const optimize = b.standardOptimizeOption(.{});

    // Create an executable for each day (except day10 which needs special linking)
    // inline for is a comptime loop - it unrolls at compile time
    inline for (.{ "day01", "day02", "day03", "day04", "day05", "day06", "day07", "day08", "day09" }) |day| {
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

    // Day 10 needs Apple's Accelerate framework for LAPACK (linear algebra)
    // This is a great example of Zig's C interop capabilities!
    {
        const day10 = b.addExecutable(.{
            .name = "day10",
            .root_module = b.createModule(.{
                .root_source_file = b.path("day10/main.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Link the Accelerate framework which includes LAPACK
        // On macOS, frameworks are linked with -framework Name
        day10.linkFramework("Accelerate");

        b.installArtifact(day10);

        const run_cmd = b.addRunArtifact(day10);
        run_cmd.step.dependOn(b.getInstallStep());
        run_cmd.setCwd(b.path("day10"));

        const run_step = b.step("run-day10", "Run day10");
        run_step.dependOn(&run_cmd.step);
    }
}
