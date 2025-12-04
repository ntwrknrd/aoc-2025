// Advent of Code 2025 - Day 1: Secret Entrance
//
// Zig is a systems language like C but with modern safety features.
// No garbage collector, no hidden control flow, explicit allocators.

const std = @import("std");

// parseRotation splits "L68" into (direction, distance)
// []const u8 is Zig's string type - a slice of constant bytes
// Similar to Rust's &str or Go's string
fn parseRotation(rotation: []const u8) struct { dir: u8, dist: i32 } {
    // rotation[0] gets the first byte - 'L' or 'R'
    const dir = rotation[0];

    // rotation[1..] slices from index 1 to end - like Python's [1:]
    // std.fmt.parseInt parses a string to an integer
    // catch unreachable means "panic if this fails" - fine for AoC
    const dist = std.fmt.parseInt(i32, rotation[1..], 10) catch unreachable;

    // Zig uses anonymous structs for multiple return values
    // .{} is shorthand when the type is known from context
    return .{ .dir = dir, .dist = dist };
}

// applyRotation moves the dial and returns new position
fn applyRotation(position: i32, dir: u8, dist: i32) i32 {
    const new_position = if (dir == 'L') position - dist else position + dist;

    // GOTCHA: Zig's @rem() can be negative, just like Go/Rust!
    // @mod() gives us Python-style modulo (always positive)
    return @mod(new_position, 100);
}

// solve counts how many times the dial lands on 0
fn solve(rotations: []const []const u8) i32 {
    var position: i32 = 50; // var means mutable, const means immutable
    var zero_count: i32 = 0;

    for (rotations) |rotation| {
        const parsed = parseRotation(rotation);
        position = applyRotation(position, parsed.dir, parsed.dist);
        if (position == 0) {
            zero_count += 1;
        }
    }

    return zero_count;
}

// countZerosCrossed counts zeros we pass through during a rotation
fn countZerosCrossed(start: i32, dir: u8, dist: i32) i32 {
    const a: i32, const b: i32 = if (dir == 'L')
        .{ start - dist, start - 1 }
    else
        .{ start + 1, start + dist };

    // @divFloor is floor division (like Python's //)
    return @divFloor(b, 100) - @divFloor(a - 1, 100);
}

// solvePart2 counts ALL times the dial points at 0 (including pass-throughs)
fn solvePart2(rotations: []const []const u8) i32 {
    var position: i32 = 50;
    var zero_count: i32 = 0;

    for (rotations) |rotation| {
        const parsed = parseRotation(rotation);
        zero_count += countZerosCrossed(position, parsed.dir, parsed.dist);
        position = applyRotation(position, parsed.dir, parsed.dist);
    }

    return zero_count;
}

// Maximum lines we'll support
const MAX_LINES = 5000;

// loadInput reads lines from a file
// Returns a slice of the lines buffer that contains actual data
// caller_content is an out-param so caller can free the memory later
fn loadInput(allocator: std.mem.Allocator, lines_buf: *[MAX_LINES][]const u8, caller_content: *[]u8) ![][]const u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    // Read all content
    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    caller_content.* = content; // give caller ownership so they can free it
    _ = try file.readAll(content);

    // Split by newlines and store in our fixed buffer
    var iter = std.mem.splitSequence(u8, content, "\n");
    var count: usize = 0;

    while (iter.next()) |line| {
        if (line.len > 0) {
            lines_buf[count] = line;
            count += 1;
        }
    }

    // Return a slice of just the lines we populated
    return lines_buf[0..count];
}

pub fn main() !void {
    // Get a general purpose allocator - Zig makes memory management explicit
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Zig 0.15 changed I/O - now we need explicit buffers for formatted output
    // std.fs.File.stdout() gives us the file handle
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {}; // make sure we flush at the end

    // Example input from the puzzle
    const example_input = [_][]const u8{
        "L68", "L30", "R48", "L5", "R60", "L55", "L1", "L99", "R14", "L82",
    };

    // Part 1
    try stdout.print("--- Part 1 ---\n", .{});
    const result = solve(&example_input);
    try stdout.print("Example: {}\n", .{result}); // should be 3

    var lines_buf: [MAX_LINES][]const u8 = undefined;
    var file_content: []u8 = undefined;
    const real_input = try loadInput(allocator, &lines_buf, &file_content);
    defer allocator.free(file_content); // free the file content when done

    const answer = solve(real_input);
    try stdout.print("Answer:  {}\n", .{answer});

    // Part 2
    try stdout.print("\n--- Part 2 ---\n", .{});
    const result2 = solvePart2(&example_input);
    try stdout.print("Example: {}\n", .{result2}); // should be 6

    const answer2 = solvePart2(real_input);
    try stdout.print("Answer:  {}\n", .{answer2});
}
