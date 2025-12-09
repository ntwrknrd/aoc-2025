// Advent of Code 2025 - Day 7: Laboratories (tachyon beam splitter manifold)
//
// Simulate beams traveling down through a grid of splitters (^).
// Part 1: count how many times any beam hits a splitter
// Part 2: count distinct timelines (many-worlds quantum interpretation)
//
// Zig doesn't have HashSet built-in, but our grid is bounded (max ~200 cols)
// so we use a simple bool array to track which columns have beams.

const std = @import("std");

const MAX_WIDTH = 200;
const MAX_LINES = 200;

// Part 1: track unique beam positions, count total splits
fn simulateBeams(grid: []const []const u8) usize {
    if (grid.len == 0) return 0;

    // find where the beam enters (the 'S')
    var start_col: usize = 0;
    for (grid[0], 0..) |ch, i| {
        if (ch == 'S') {
            start_col = i;
            break;
        }
    }

    // track active beam positions as a bool array (like a set)
    // true = beam present at this column
    var beams: [MAX_WIDTH]bool = [_]bool{false} ** MAX_WIDTH;
    beams[start_col] = true;

    var total_splits: usize = 0;

    // simulate each row from top to bottom
    for (1..grid.len) |row| {
        const line = grid[row];
        var new_beams: [MAX_WIDTH]bool = [_]bool{false} ** MAX_WIDTH;

        for (0..MAX_WIDTH) |col| {
            if (!beams[col]) continue;

            // check if this beam hits a splitter
            if (col < line.len and line[col] == '^') {
                // beam hit a splitter! count it and spawn left/right
                total_splits += 1;

                if (col > 0) {
                    new_beams[col - 1] = true;
                }
                if (col + 1 < line.len) {
                    new_beams[col + 1] = true;
                }
            } else {
                // empty space - beam continues straight down
                if (col < line.len) {
                    new_beams[col] = true;
                }
            }
        }

        beams = new_beams;

        // check if any beams left
        var any_beams = false;
        for (beams) |b| {
            if (b) {
                any_beams = true;
                break;
            }
        }
        if (!any_beams) break;
    }

    return total_splits;
}

// Part 2: count distinct timelines using many-worlds interpretation
fn countTimelines(grid: []const []const u8) u64 {
    if (grid.len == 0) return 0;

    // find where the beam enters (the 'S')
    var start_col: usize = 0;
    for (grid[0], 0..) |ch, i| {
        if (ch == 'S') {
            start_col = i;
            break;
        }
    }

    // track particle COUNTS at each position (not just presence)
    // particles at same position are still distinct timelines
    var particles: [MAX_WIDTH]u64 = [_]u64{0} ** MAX_WIDTH;
    particles[start_col] = 1;

    for (1..grid.len) |row| {
        const line = grid[row];
        var new_particles: [MAX_WIDTH]u64 = [_]u64{0} ** MAX_WIDTH;

        for (0..MAX_WIDTH) |col| {
            const count = particles[col];
            if (count == 0) continue;

            if (col < line.len and line[col] == '^') {
                // particle splits into two timelines (left and right)
                if (col > 0) {
                    new_particles[col - 1] += count;
                }
                if (col + 1 < line.len) {
                    new_particles[col + 1] += count;
                }
            } else if (col < line.len) {
                // continues down - preserves all timeline counts
                new_particles[col] += count;
            }
        }

        particles = new_particles;

        // check if any particles left
        var total: u64 = 0;
        for (particles) |p| total += p;
        if (total == 0) break;
    }

    // total timelines = sum of all particle counts
    var total: u64 = 0;
    for (particles) |p| total += p;
    return total;
}

pub fn main() !void {
    // Zig 0.15 buffered stdout
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // load input file
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    // split into lines
    var lines_buf: [MAX_LINES][]const u8 = undefined;
    var line_count: usize = 0;

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        // skip trailing empty lines
        if (line.len == 0 and line_iter.peek() == null) continue;
        lines_buf[line_count] = line;
        line_count += 1;
    }

    const grid = lines_buf[0..line_count];

    try stdout.print("--- Part 1 ---\n", .{});
    const part1 = simulateBeams(grid);
    try stdout.print("Answer: {}\n", .{part1});

    try stdout.print("\n--- Part 2 ---\n", .{});
    const part2 = countTimelines(grid);
    try stdout.print("Answer: {}\n", .{part2});
}
