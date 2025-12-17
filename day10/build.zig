const std = @import("std");

// build.zig is Zig's way of handling build configuration - similar to
// Makefiles or Cargo.toml but written in Zig itself. This lets us specify
// linking options, optimization levels, and other build settings.

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // default to ReleaseFast for speed - override with -Doptimize=Debug if needed
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const exe = b.addExecutable(.{
        .name = "day10",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            // link libc and Accelerate framework for LAPACK (dgesv_, dgels_)
            .link_libc = true,
        }),
    });

    // link Apple's Accelerate framework which provides LAPACK
    // this is what gives us dgesv_ and dgels_ for solving linear systems
    exe.linkFramework("Accelerate");

    b.installArtifact(exe);

    // create a "run" step so we can do: zig build run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the solution");
    run_step.dependOn(&run_cmd.step);
}
