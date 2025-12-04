// Advent of Code 2025 - Day 3: Lobby
//
// Greedy digit selection - pick the best digit left-to-right while leaving
// room for remaining picks.

const std = @import("std");

// maxJoltage finds the largest 2-digit number from picking two batteries at i < j
fn maxJoltage(bank: []const u8) u32 {
    const n = bank.len;

    // suffix_max[i] = largest digit from position i to the end
    // we'll build it backwards
    var suffix_max: [100]u8 = undefined;
    suffix_max[n - 1] = bank[n - 1] - '0';

    // work backwards from second-to-last element
    var i: usize = n - 1;
    while (i > 0) {
        i -= 1;
        const digit = bank[i] - '0';
        suffix_max[i] = @max(digit, suffix_max[i + 1]);
    }

    // try each position as tens digit
    var max_val: u32 = 0;
    i = 0;
    while (i < n - 1) : (i += 1) {
        const tens: u32 = bank[i] - '0';
        const units: u32 = suffix_max[i + 1];
        const candidate = tens * 10 + units;
        max_val = @max(max_val, candidate);
    }

    return max_val;
}

// solve sums max 2-digit joltage for each bank
fn solve(lines: []const []const u8) u32 {
    var total: u32 = 0;
    for (lines) |line| {
        total += maxJoltage(line);
    }
    return total;
}

// maxJoltageK finds the largest k-digit number using greedy selection
// Pick digits left-to-right, always grabbing the largest we can while
// still leaving room for remaining picks
fn maxJoltageK(bank: []const u8, k: usize) u64 {
    const n = bank.len;

    var result: [20]u8 = undefined; // max k=12, but room for more
    var start: usize = 0;

    var digit_idx: usize = 0;
    while (digit_idx < k) : (digit_idx += 1) {
        const remaining = k - digit_idx - 1;
        const end = n - remaining;

        // find the largest digit in [start, end)
        var best_pos = start;
        var j = start + 1;
        while (j < end) : (j += 1) {
            if (bank[j] > bank[best_pos]) {
                best_pos = j;
            }
        }

        result[digit_idx] = bank[best_pos];
        start = best_pos + 1;
    }

    // parse our assembled digits into a u64
    // std.fmt.parseInt works on slices
    return std.fmt.parseInt(u64, result[0..k], 10) catch unreachable;
}

// solvePart2 sums max 12-digit joltage for each bank
fn solvePart2(lines: []const []const u8) u64 {
    var total: u64 = 0;
    for (lines) |line| {
        total += maxJoltageK(line, 12);
    }
    return total;
}

const MAX_LINES = 5000;

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
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111",
    };

    // Part 1
    try stdout.print("--- Part 1 ---\n", .{});
    const result = solve(&example_input);
    try stdout.print("Example: {}\n", .{result}); // should be 357

    var lines_buf: [MAX_LINES][]const u8 = undefined;
    var file_content: []u8 = undefined;
    const real_input = try loadInput(allocator, &lines_buf, &file_content);
    defer allocator.free(file_content);

    const answer = solve(real_input);
    try stdout.print("Answer:  {}\n", .{answer});

    // Part 2
    try stdout.print("\n--- Part 2 ---\n", .{});
    const result2 = solvePart2(&example_input);
    try stdout.print("Example: {}\n", .{result2}); // should be 3121910778619

    const answer2 = solvePart2(real_input);
    try stdout.print("Answer:  {}\n", .{answer2});
}
