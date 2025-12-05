// Advent of Code 2025 - Day 5: Cafeteria ingredient freshness
//
// Range checking and merging overlapping intervals.

const std = @import("std");

// Range represents a start-end range of valid ingredient IDs
const Range = struct {
    start: i64,
    end: i64,
};

// check if an ingredient ID falls within any of the ranges
fn inRange(id: i64, ranges: []const Range) bool {
    for (ranges) |r| {
        if (id >= r.start and id <= r.end) {
            return true;
        }
    }
    return false;
}

// comparison function for sorting ranges by start value
// Zig 0.15's sort expects a bool (is a < b?)
fn rangeCompare(_: void, a: Range, b: Range) bool {
    return a.start < b.start;
}

// merge overlapping/adjacent ranges into minimal set
// uses a pre-allocated buffer to avoid ArrayList API changes
fn mergeRanges(ranges: []Range, merged_buf: []Range) []Range {
    if (ranges.len == 0) {
        return merged_buf[0..0];
    }

    // sort by start value
    std.mem.sort(Range, ranges, {}, rangeCompare);

    // build merged list using the buffer
    merged_buf[0] = ranges[0];
    var merged_count: usize = 1;

    for (ranges[1..]) |r| {
        const last = &merged_buf[merged_count - 1];

        // if this range overlaps or touches the previous one, extend it
        if (r.start <= last.end + 1) {
            last.end = @max(last.end, r.end);
        } else {
            // no overlap, start a new merged range
            merged_buf[merged_count] = r;
            merged_count += 1;
        }
    }

    return merged_buf[0..merged_count];
}

const MAX_RANGES = 2000;
const MAX_INGREDIENTS = 2000;

fn loadInput(allocator: std.mem.Allocator, ranges_out: *[]Range, ingredients_out: *[]i64) !void {
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    // split on double newline to separate sections
    var sections = std.mem.splitSequence(u8, content, "\n\n");
    const range_section = sections.next() orelse return error.InvalidInput;
    const ingredient_section = sections.next() orelse return error.InvalidInput;

    // parse ranges
    var ranges = try allocator.alloc(Range, MAX_RANGES);
    var range_count: usize = 0;
    var range_lines = std.mem.splitScalar(u8, range_section, '\n');

    while (range_lines.next()) |line| {
        if (line.len == 0) continue;

        // find the dash separator - parseInt needs exact slice
        var parts = std.mem.splitScalar(u8, line, '-');
        const start_str = parts.next() orelse continue;
        const end_str = parts.next() orelse continue;

        ranges[range_count] = .{
            .start = try std.fmt.parseInt(i64, start_str, 10),
            .end = try std.fmt.parseInt(i64, end_str, 10),
        };
        range_count += 1;
    }

    // parse ingredient IDs
    var ingredients = try allocator.alloc(i64, MAX_INGREDIENTS);
    var ing_count: usize = 0;
    var ing_lines = std.mem.splitScalar(u8, ingredient_section, '\n');

    while (ing_lines.next()) |line| {
        if (line.len == 0) continue;
        ingredients[ing_count] = try std.fmt.parseInt(i64, line, 10);
        ing_count += 1;
    }

    ranges_out.* = ranges[0..range_count];
    ingredients_out.* = ingredients[0..ing_count];
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Zig 0.15 changed the stdout API - now uses buffered writer
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    var ranges: []Range = undefined;
    var ingredients: []i64 = undefined;
    try loadInput(allocator, &ranges, &ingredients);
    defer allocator.free(ranges.ptr[0..MAX_RANGES]);
    defer allocator.free(ingredients.ptr[0..MAX_INGREDIENTS]);

    // Part 1: count fresh ingredients (those in ANY range)
    var part1: usize = 0;
    for (ingredients) |id| {
        if (inRange(id, ranges)) {
            part1 += 1;
        }
    }
    try stdout.print("Part 1: {}\n", .{part1});

    // Part 2: count ALL unique IDs covered by merged ranges
    // need a mutable copy for sorting
    const ranges_copy = try allocator.alloc(Range, ranges.len);
    defer allocator.free(ranges_copy);
    @memcpy(ranges_copy, ranges);

    // buffer for merged ranges - can't be larger than input
    var merged_buf: [MAX_RANGES]Range = undefined;
    const merged = mergeRanges(ranges_copy, &merged_buf);

    var part2: i64 = 0;
    for (merged) |r| {
        // each range covers (end - start + 1) unique IDs
        part2 += r.end - r.start + 1;
    }
    try stdout.print("Part 2: {}\n", .{part2});
}
