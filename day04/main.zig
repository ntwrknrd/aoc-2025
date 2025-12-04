// Advent of Code 2025 - Day 4: Printing Department
//
// Grid neighbor counting with iterative removal.

const std = @import("std");

// countNeighbors checks how many @ symbols surround a cell (8 directions)
fn countNeighbors(grid: [][]u8, row: usize, col: usize) usize {
    const rows = grid.len;
    const cols = grid[0].len;
    var count: usize = 0;

    // Check all 8 directions using signed arithmetic for bounds
    const deltas = [_][2]i32{
        .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
        .{ 0, -1 },             .{ 0, 1 },
        .{ 1, -1 },  .{ 1, 0 },  .{ 1, 1 },
    };

    for (deltas) |delta| {
        const dr = delta[0];
        const dc = delta[1];

        // convert to signed for arithmetic
        const nr: i32 = @as(i32, @intCast(row)) + dr;
        const nc: i32 = @as(i32, @intCast(col)) + dc;

        // bounds check
        if (nr >= 0 and nc >= 0) {
            const nr_u: usize = @intCast(nr);
            const nc_u: usize = @intCast(nc);
            if (nr_u < rows and nc_u < cols and grid[nr_u][nc_u] == '@') {
                count += 1;
            }
        }
    }

    return count;
}

// Position struct for storing row,col pairs
const Position = struct {
    row: usize,
    col: usize,
};

// copyGrid makes a mutable copy of a const grid
fn copyGrid(grid_const: []const []const u8, allocator: std.mem.Allocator) ![][]u8 {
    const rows = grid_const.len;
    const cols = grid_const[0].len;

    const grid = try allocator.alloc([]u8, rows);
    for (grid, 0..) |*row_ptr, i| {
        row_ptr.* = try allocator.alloc(u8, cols);
        @memcpy(row_ptr.*, grid_const[i]);
    }
    return grid;
}

// freeGrid cleans up a grid allocated by copyGrid
fn freeGrid(grid: [][]u8, allocator: std.mem.Allocator) void {
    for (grid) |row| {
        allocator.free(row);
    }
    allocator.free(grid);
}

// findAccessible returns count of rolls with < 4 neighbors, stores positions in buffer
fn findAccessible(grid: [][]u8, accessible: *[10000]Position) usize {
    var count: usize = 0;

    for (grid, 0..) |row_data, row| {
        for (row_data, 0..) |cell, col| {
            if (cell == '@') {
                const neighbors = countNeighbors(grid, row, col);
                if (neighbors < 4) {
                    accessible[count] = .{ .row = row, .col = col };
                    count += 1;
                }
            }
        }
    }

    return count;
}

// solve counts rolls accessible by forklift (part 1)
fn solve(grid_const: []const []const u8, allocator: std.mem.Allocator) !usize {
    const grid = try copyGrid(grid_const, allocator);
    defer freeGrid(grid, allocator);

    var accessible: [10000]Position = undefined;
    return findAccessible(grid, &accessible);
}

// solvePart2 keeps removing accessible rolls until none left
fn solvePart2(grid_const: []const []const u8, allocator: std.mem.Allocator) !usize {
    const grid = try copyGrid(grid_const, allocator);
    defer freeGrid(grid, allocator);

    var total_removed: usize = 0;
    var accessible: [10000]Position = undefined;

    // keep removing until no accessible rolls remain
    while (true) {
        const count = findAccessible(grid, &accessible);
        if (count == 0) break;

        // remove all accessible rolls
        for (accessible[0..count]) |pos| {
            grid[pos.row][pos.col] = '.';
        }

        total_removed += count;
    }

    return total_removed;
}

const MAX_LINES = 200;

fn loadInput(allocator: std.mem.Allocator, lines_buf: *[MAX_LINES][]const u8, caller_content: *[]u8) ![][]const u8 {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    caller_content.* = content;
    _ = try file.readAll(content);

    var iter = std.mem.splitSequence(u8, content, "\n");
    var count: usize = 0;

    while (iter.next()) |line| {
        if (line.len > 0) {
            lines_buf[count] = line;
            count += 1;
        }
    }

    return lines_buf[0..count];
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    // example from the puzzle
    const example_input = [_][]const u8{
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };

    // Part 1
    try stdout.print("--- Part 1 ---\n", .{});
    const result = try solve(&example_input, allocator);
    try stdout.print("Example: {}\n", .{result}); // should be 13

    var lines_buf: [MAX_LINES][]const u8 = undefined;
    var file_content: []u8 = undefined;
    const real_input = try loadInput(allocator, &lines_buf, &file_content);
    defer allocator.free(file_content);

    const answer = try solve(real_input, allocator);
    try stdout.print("Answer:  {}\n", .{answer});

    // Part 2
    try stdout.print("\n--- Part 2 ---\n", .{});
    const result2 = try solvePart2(&example_input, allocator);
    try stdout.print("Example: {}\n", .{result2}); // should be 43

    const answer2 = try solvePart2(real_input, allocator);
    try stdout.print("Answer:  {}\n", .{answer2});
}
