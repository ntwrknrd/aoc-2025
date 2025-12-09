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

const VerticalEdge = struct {
    x: i64,
    y_lo: i64,
    y_hi: i64,
};

fn solvePart2(tiles: []const Point, allocator: std.mem.Allocator) !i64 {
    if (tiles.len < 2) return 0;

    const n = tiles.len;

    // build vertical edges from consecutive red tiles
    var vertical_edges = try allocator.alloc(VerticalEdge, n);
    defer allocator.free(vertical_edges);
    var num_edges: usize = 0;

    for (0..n) |i| {
        const x1 = tiles[i].x;
        const y1 = tiles[i].y;
        const x2 = tiles[(i + 1) % n].x;
        const y2 = tiles[(i + 1) % n].y;
        if (x1 == x2) {
            vertical_edges[num_edges] = .{ .x = x1, .y_lo = @min(y1, y2), .y_hi = @max(y1, y2) };
            num_edges += 1;
        }
    }
    const edges = vertical_edges[0..num_edges];

    // collect unique y-values using indexOfScalar for cleaner dedup
    var y_buf = try allocator.alloc(i64, n);
    defer allocator.free(y_buf);
    var num_ys: usize = 0;

    for (tiles) |p| {
        if (std.mem.indexOfScalar(i64, y_buf[0..num_ys], p.y) == null) {
            y_buf[num_ys] = p.y;
            num_ys += 1;
        }
    }

    // sort y-values (enables binary search later)
    std.mem.sort(i64, y_buf[0..num_ys], {}, std.sort.asc(i64));
    const all_ys = y_buf[0..num_ys];
    const k = all_ys.len;

    // compute left[y] and right[y] for each unique y
    var left_arr = try allocator.alloc(i64, k);
    defer allocator.free(left_arr);
    var right_arr = try allocator.alloc(i64, k);
    defer allocator.free(right_arr);

    for (all_ys, 0..) |y, i| {
        var min_x: i64 = std.math.maxInt(i64);
        var max_x: i64 = std.math.minInt(i64);

        for (edges) |edge| {
            if (edge.y_lo <= y and y <= edge.y_hi) {
                min_x = @min(min_x, edge.x);
                max_x = @max(max_x, edge.x);
            }
        }
        for (tiles) |p| {
            if (p.y == y) {
                min_x = @min(min_x, p.x);
                max_x = @max(max_x, p.x);
            }
        }

        left_arr[i] = min_x;
        right_arr[i] = max_x;
    }

    // build sparse tables - flattened to single allocation
    // log_k levels, k entries each, 2 tables (max_left + min_right)
    const log_k = if (k > 1) std.math.log2_int(usize, k) + 1 else 1;
    var sparse = try allocator.alloc(i64, log_k * k * 2);
    defer allocator.free(sparse);

    // helper to index into flattened sparse table
    // table 0 = max_left, table 1 = min_right
    const idx = struct {
        fn f(table: usize, level: usize, pos: usize, kk: usize, log_kk: usize) usize {
            return table * log_kk * kk + level * kk + pos;
        }
    }.f;

    // initialize level 0
    for (0..k) |i| {
        sparse[idx(0, 0, i, k, log_k)] = left_arr[i];
        sparse[idx(1, 0, i, k, log_k)] = right_arr[i];
    }

    // build higher levels
    var j: usize = 1;
    while (j < log_k) : (j += 1) {
        const half: usize = @as(usize, 1) << @intCast(j - 1);
        const step: usize = half << 1;
        if (step > k) continue;

        for (0..(k - step + 1)) |i| {
            sparse[idx(0, j, i, k, log_k)] = @max(
                sparse[idx(0, j - 1, i, k, log_k)],
                sparse[idx(0, j - 1, i + half, k, log_k)],
            );
            sparse[idx(1, j, i, k, log_k)] = @min(
                sparse[idx(1, j - 1, i, k, log_k)],
                sparse[idx(1, j - 1, i + half, k, log_k)],
            );
        }
    }

    // check all pairs of red tiles
    var max_area: i64 = 0;

    var i: usize = 0;
    while (i < n) : (i += 1) {
        const x1 = tiles[i].x;
        const y1 = tiles[i].y;

        var ji: usize = i + 1;
        while (ji < n) : (ji += 1) {
            const x2 = tiles[ji].x;
            const y2 = tiles[ji].y;

            const rx_lo = @min(x1, x2);
            const rx_hi = @max(x1, x2);
            const ry_lo = @min(y1, y2);
            const ry_hi = @max(y1, y2);

            const potential = (rx_hi - rx_lo + 1) * (ry_hi - ry_lo + 1);
            if (potential <= max_area) continue;

            // binary search for y indices (O(log k) vs O(k))
            // Zig 0.15 binarySearch: fn(context, element) -> Order
            const cmp = struct {
                fn f(target: i64, elem: i64) std.math.Order {
                    return std.math.order(target, elem);
                }
            }.f;
            const iy_lo = std.sort.binarySearch(i64, all_ys, ry_lo, cmp).?;
            const iy_hi = std.sort.binarySearch(i64, all_ys, ry_hi, cmp).?;

            // query sparse tables using std.math.log2_int
            const length = iy_hi - iy_lo + 1;
            const j_level = std.math.log2_int(usize, length);
            const span: usize = @as(usize, 1) << @intCast(j_level);
            const idx2 = iy_hi + 1 - span;

            const ml = @max(sparse[idx(0, j_level, iy_lo, k, log_k)], sparse[idx(0, j_level, idx2, k, log_k)]);
            const mr = @min(sparse[idx(1, j_level, iy_lo, k, log_k)], sparse[idx(1, j_level, idx2, k, log_k)]);

            if (ml <= rx_lo and mr >= rx_hi) {
                max_area = potential;
            }
        }
    }

    return max_area;
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

    try stdout.print("--- Part 2 ---\n", .{});
    const part2 = try solvePart2(tiles, allocator);
    try stdout.print("Answer: {}\n", .{part2});
}
