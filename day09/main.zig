// Advent of Code 2025 - Day 9: Movie Theater (largest rectangle from tile corners)
//
// O(n) approach: the optimal rectangle always involves "extreme" points.
// We track 8 extremes (4 axis-aligned + 4 diagonal) and check only those pairs.

const std = @import("std");

const Point = struct {
    x: i64,
    y: i64,
};

fn solve(tiles: []const Point) i64 {
    if (tiles.len < 2) return 0;

    // track extreme points in a single pass
    var min_x_pt = tiles[0];
    var max_x_pt = tiles[0];
    var min_y_pt = tiles[0];
    var max_y_pt = tiles[0];
    var min_sum_pt = tiles[0]; // x+y extremes (diagonal)
    var max_sum_pt = tiles[0];
    var min_diff_pt = tiles[0]; // x-y extremes (anti-diagonal)
    var max_diff_pt = tiles[0];

    for (tiles) |p| {
        // axis-aligned extremes
        if (p.x < min_x_pt.x) min_x_pt = p;
        if (p.x > max_x_pt.x) max_x_pt = p;
        if (p.y < min_y_pt.y) min_y_pt = p;
        if (p.y > max_y_pt.y) max_y_pt = p;

        // diagonal extremes
        const sum = p.x + p.y;
        const diff = p.x - p.y;
        if (sum < min_sum_pt.x + min_sum_pt.y) min_sum_pt = p;
        if (sum > max_sum_pt.x + max_sum_pt.y) max_sum_pt = p;
        if (diff < min_diff_pt.x - min_diff_pt.y) min_diff_pt = p;
        if (diff > max_diff_pt.x - max_diff_pt.y) max_diff_pt = p;
    }

    // collect candidates in a fixed array (at most 8)
    const all_candidates = [_]Point{
        min_x_pt, max_x_pt, min_y_pt, max_y_pt,
        min_sum_pt, max_sum_pt, min_diff_pt, max_diff_pt,
    };

    // deduplicate by checking for unique points
    var candidates: [8]Point = undefined;
    var num_candidates: usize = 0;

    outer: for (all_candidates) |p| {
        // check if we already have this point
        for (candidates[0..num_candidates]) |existing| {
            if (existing.x == p.x and existing.y == p.y) {
                continue :outer;
            }
        }
        candidates[num_candidates] = p;
        num_candidates += 1;
    }

    // check all pairs among candidates (at most 28 pairs)
    var max_area: i64 = 0;
    for (0..num_candidates) |i| {
        for ((i + 1)..num_candidates) |j| {
            const p1 = candidates[i];
            const p2 = candidates[j];
            // +1 because tiles are squares - both corners included
            const width = absInt(p2.x - p1.x) + 1;
            const height = absInt(p2.y - p1.y) + 1;
            const area = width * height;
            if (area > max_area) max_area = area;
        }
    }

    return max_area;
}

// Zig's @abs only works on unsigned, so we need our own for signed
fn absInt(x: i64) i64 {
    return if (x < 0) -x else x;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // load input
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    // count lines first
    var line_count: usize = 0;
    var count_iter = std.mem.splitScalar(u8, content, '\n');
    while (count_iter.next()) |line| {
        if (line.len > 0) line_count += 1;
    }

    // parse points
    var tiles = try allocator.alloc(Point, line_count);
    defer allocator.free(tiles);

    var idx: usize = 0;
    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        tiles[idx] = Point{ .x = x, .y = y };
        idx += 1;
    }

    // Zig 0.15 uses std.fs.File.stdout() instead of std.io.getStdOut()
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    try stdout.print("--- Part 1 ---\n", .{});
    const part1 = solve(tiles);
    try stdout.print("Answer: {}\n", .{part1});
}
