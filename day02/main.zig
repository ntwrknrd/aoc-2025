// Advent of Code 2025 - Day 2: Gift Shop
//
// Zig version uses pure math instead of string manipulation - no allocations needed
// for the core logic, which is more idiomatic for Zig.

const std = @import("std");

// pow calculates base^exp for i64
fn pow(base: i64, exp: u32) i64 {
    var result: i64 = 1;
    var i: u32 = 0;
    while (i < exp) : (i += 1) {
        result *= base;
    }
    return result;
}

// countDigits returns how many digits in a number
fn countDigits(n: i64) u32 {
    if (n == 0) return 1;
    var count: u32 = 0;
    var temp = n;
    while (temp > 0) : (temp = @divFloor(temp, 10)) {
        count += 1;
    }
    return count;
}

// isDouble checks if a number is made of a digit sequence repeated twice (like 6464)
// uses pure math: split number into first half and second half, compare
fn isDouble(n: i64) bool {
    if (n < 10) return false; // single digit can't be a double

    const digits = countDigits(n);
    if (digits % 2 != 0) return false; // odd digit count can't be a double

    const half_digits = digits / 2;
    const divisor = pow(10, half_digits);
    const first_half = @divFloor(n, divisor);
    const second_half = @mod(n, divisor);

    return first_half == second_half;
}

// isRepeating checks if a number is a pattern repeated 2+ times (111, 1212, etc)
// uses pure math: extract pattern from rightmost digits, check if whole number matches
fn isRepeating(n: i64) bool {
    const digits = countDigits(n);
    if (digits < 2) return false;

    // try each possible pattern length that divides evenly
    var pattern_len: u32 = 1;
    while (pattern_len <= digits / 2) : (pattern_len += 1) {
        if (digits % pattern_len != 0) continue;

        const divisor = pow(10, pattern_len);
        const pattern = @mod(n, divisor); // rightmost pattern_len digits

        // check if the whole number is just this pattern repeated
        var check = n;
        var valid = true;
        const reps = digits / pattern_len;
        var i: u32 = 0;
        while (i < reps) : (i += 1) {
            if (@mod(check, divisor) != pattern) {
                valid = false;
                break;
            }
            check = @divFloor(check, divisor);
        }
        if (valid) return true;
    }
    return false;
}

// generateDoublesInRange finds all double numbers by checking each candidate
fn generateDoublesInRange(start: i64, end: i64, result: *[10000]i64) usize {
    var count: usize = 0;
    var n = start;
    while (n <= end) : (n += 1) {
        if (isDouble(n)) {
            result[count] = n;
            count += 1;
        }
    }
    return count;
}

// generateRepeatingInRange finds all repeating-pattern numbers by checking each candidate
fn generateRepeatingInRange(start: i64, end: i64, result: *[10000]i64) usize {
    var count: usize = 0;
    var n = start;
    while (n <= end) : (n += 1) {
        if (isRepeating(n)) {
            result[count] = n;
            count += 1;
        }
    }
    return count;
}

// parseInput splits "11-22,95-115" into array of (start, end) pairs
fn parseInput(line: []const u8, ranges: *[100][2]i64) usize {
    var count: usize = 0;

    // split by comma
    var parts = std.mem.splitSequence(u8, line, ",");
    while (parts.next()) |part| {
        // split by dash
        var nums = std.mem.splitSequence(u8, part, "-");
        const start_str = nums.next() orelse continue;
        const end_str = nums.next() orelse continue;

        const start_num = std.fmt.parseInt(i64, start_str, 10) catch continue;
        const end_num = std.fmt.parseInt(i64, end_str, 10) catch continue;

        ranges[count][0] = start_num;
        ranges[count][1] = end_num;
        count += 1;
    }

    return count;
}

// solve sums all IDs found by finder_fn across all ranges
fn solve(input_line: []const u8, comptime finder_fn: fn (i64, i64, *[10000]i64) usize) i64 {
    var ranges: [100][2]i64 = undefined;
    const range_count = parseInput(input_line, &ranges);

    var total: i64 = 0;
    var buffer: [10000]i64 = undefined;

    var i: usize = 0;
    while (i < range_count) : (i += 1) {
        const start = ranges[i][0];
        const end = ranges[i][1];

        const count = finder_fn(start, end, &buffer);
        var j: usize = 0;
        while (j < count) : (j += 1) {
            total += buffer[j];
        }
    }

    return total;
}

pub fn main() !void {
    // Zig 0.15 I/O with explicit buffer
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    const example_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    // Read real input
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    const stat = try file.stat();
    const real_input = try allocator.alloc(u8, stat.size);
    defer allocator.free(real_input);
    _ = try file.readAll(real_input);
    const trimmed = std.mem.trim(u8, real_input, " \n\r\t");

    // Part 1: doubles like 6464
    try stdout.print("--- Part 1 ---\n", .{});
    const result = solve(example_input, generateDoublesInRange);
    try stdout.print("Example: {}\n", .{result}); // should be 1227775554
    const answer = solve(trimmed, generateDoublesInRange);
    try stdout.print("Answer:  {}\n", .{answer});

    // Part 2: any repeating pattern like 111, 1212, 824824824
    try stdout.print("\n--- Part 2 ---\n", .{});
    const result2 = solve(example_input, generateRepeatingInRange);
    try stdout.print("Example: {}\n", .{result2}); // should be 4174379265
    const answer2 = solve(trimmed, generateRepeatingInRange);
    try stdout.print("Answer:  {}\n", .{answer2});
}
