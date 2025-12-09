// Advent of Code 2025 - Day 6: Trash Compactor (cephalopod math worksheet)
//
// Columnar parsing of a math worksheet - numbers stacked vertically,
// operators at the bottom. Part 2 reads digits column-wise (transposed).

const std = @import("std");

const MAX_LINES = 10;
const MAX_LINE_LEN = 2000;
const MAX_PROBLEMS = 1000;
const MAX_NUMBERS = 10;

// a boundary marks where a problem starts and ends (column indices)
const Boundary = struct {
    start: usize,
    end: usize,
};

// a problem has numbers and an operator
const Problem = struct {
    numbers: [MAX_NUMBERS]i64,
    count: usize,
    op: u8, // '+' or '*'
};

// find problem boundaries by looking for columns that are all spaces
fn findProblemBoundaries(
    lines: []const []const u8,
    width: usize,
    bounds_buf: *[MAX_PROBLEMS]Boundary,
) []Boundary {
    var bounds_count: usize = 0;
    var start: ?usize = null;

    for (0..width) |col| {
        // check if this column is all spaces
        var all_spaces = true;
        for (lines) |line| {
            // pad access: if line is shorter, treat as space
            const ch = if (col < line.len) line[col] else ' ';
            if (ch != ' ') {
                all_spaces = false;
                break;
            }
        }

        if (!all_spaces and start == null) {
            // found start of a problem
            start = col;
        } else if (all_spaces and start != null) {
            // found end of a problem
            bounds_buf[bounds_count] = .{ .start = start.?, .end = col };
            bounds_count += 1;
            start = null;
        }
    }

    // don't forget the last problem
    if (start != null) {
        bounds_buf[bounds_count] = .{ .start = start.?, .end = width };
        bounds_count += 1;
    }

    return bounds_buf[0..bounds_count];
}

// helper to parse a trimmed number string
fn parseNumber(slice: []const u8) ?i64 {
    // manual trim - find first and last non-space
    var trimmed_start: usize = 0;
    var trimmed_end: usize = slice.len;

    while (trimmed_start < slice.len and slice[trimmed_start] == ' ') {
        trimmed_start += 1;
    }
    while (trimmed_end > trimmed_start and slice[trimmed_end - 1] == ' ') {
        trimmed_end -= 1;
    }

    if (trimmed_start >= trimmed_end) {
        return null;
    }

    const trimmed = slice[trimmed_start..trimmed_end];
    return std.fmt.parseInt(i64, trimmed, 10) catch null;
}

// parse worksheet Part 1 style: numbers from each row
fn parseWorksheet(
    lines: []const []const u8,
    width: usize,
    problems_buf: *[MAX_PROBLEMS]Problem,
) []Problem {
    var bounds_buf: [MAX_PROBLEMS]Boundary = undefined;
    const bounds = findProblemBoundaries(lines, width, &bounds_buf);

    // last line is operators, rest are numbers
    const num_lines = lines.len - 1;
    const op_line = lines[lines.len - 1];

    var prob_count: usize = 0;

    for (bounds) |b| {
        var prob = Problem{ .numbers = undefined, .count = 0, .op = '+' };

        // grab number from each row's slice
        for (0..num_lines) |row| {
            const line = lines[row];
            // safe slice: clamp to line length
            const start = @min(b.start, line.len);
            const end = @min(b.end, line.len);
            if (start < end) {
                if (parseNumber(line[start..end])) |num| {
                    prob.numbers[prob.count] = num;
                    prob.count += 1;
                }
            }
        }

        // find operator in this range
        const op_start = @min(b.start, op_line.len);
        const op_end = @min(b.end, op_line.len);
        if (op_start < op_end) {
            for (op_line[op_start..op_end]) |ch| {
                if (ch == '+' or ch == '*') {
                    prob.op = ch;
                    break;
                }
            }
        }

        problems_buf[prob_count] = prob;
        prob_count += 1;
    }

    return problems_buf[0..prob_count];
}

// parse worksheet cephalopod style (Part 2): digits in columns, right-to-left
fn parseWorksheetCephalopod(
    lines: []const []const u8,
    width: usize,
    problems_buf: *[MAX_PROBLEMS]Problem,
) []Problem {
    var bounds_buf: [MAX_PROBLEMS]Boundary = undefined;
    const bounds = findProblemBoundaries(lines, width, &bounds_buf);

    const num_lines = lines.len - 1;
    const op_line = lines[lines.len - 1];

    var prob_count: usize = 0;

    for (bounds) |b| {
        var prob = Problem{ .numbers = undefined, .count = 0, .op = '+' };

        // iterate columns right-to-left
        var col: usize = b.end;
        while (col > b.start) {
            col -= 1;

            // collect digits from top to bottom
            var digits_buf: [MAX_LINES]u8 = undefined;
            var digit_count: usize = 0;

            for (0..num_lines) |row| {
                const line = lines[row];
                const ch = if (col < line.len) line[col] else ' ';
                // check if it's a digit (ASCII 0-9)
                if (ch >= '0' and ch <= '9') {
                    digits_buf[digit_count] = ch;
                    digit_count += 1;
                }
            }

            if (digit_count > 0) {
                if (std.fmt.parseInt(i64, digits_buf[0..digit_count], 10)) |num| {
                    prob.numbers[prob.count] = num;
                    prob.count += 1;
                } else |_| {}
            }
        }

        // find operator
        const op_start = @min(b.start, op_line.len);
        const op_end = @min(b.end, op_line.len);
        if (op_start < op_end) {
            for (op_line[op_start..op_end]) |ch| {
                if (ch == '+' or ch == '*') {
                    prob.op = ch;
                    break;
                }
            }
        }

        problems_buf[prob_count] = prob;
        prob_count += 1;
    }

    return problems_buf[0..prob_count];
}

// solve by applying operator to each problem and summing results
fn solve(problems: []const Problem) i64 {
    var total: i64 = 0;

    for (problems) |prob| {
        var result: i64 = if (prob.op == '+') 0 else 1;

        for (prob.numbers[0..prob.count]) |n| {
            if (prob.op == '+') {
                result += n;
            } else {
                result *= n;
            }
        }

        total += result;
    }

    return total;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Zig 0.15 buffered stdout
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    // example for testing
    const example = [_][]const u8{
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    };
    const example_width: usize = 15;

    try stdout.print("--- Part 1 ---\n", .{});

    var ex_problems: [MAX_PROBLEMS]Problem = undefined;
    const ex_parsed = parseWorksheet(&example, example_width, &ex_problems);
    try stdout.print("Example: {} (expected 4277556)\n", .{solve(ex_parsed)});

    // load real input
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    // split into lines
    var lines_buf: [MAX_LINES][]const u8 = undefined;
    var line_count: usize = 0;
    var max_width: usize = 0;

    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        // skip trailing empty lines
        if (line.len == 0 and line_iter.peek() == null) continue;
        lines_buf[line_count] = line;
        if (line.len > max_width) max_width = line.len;
        line_count += 1;
    }

    const lines = lines_buf[0..line_count];

    var problems: [MAX_PROBLEMS]Problem = undefined;
    const parsed = parseWorksheet(lines, max_width, &problems);
    try stdout.print("Answer:  {}\n", .{solve(parsed)});

    try stdout.print("\n--- Part 2 ---\n", .{});

    var ex_problems2: [MAX_PROBLEMS]Problem = undefined;
    const ex_parsed2 = parseWorksheetCephalopod(&example, example_width, &ex_problems2);
    try stdout.print("Example: {} (expected 3263827)\n", .{solve(ex_parsed2)});

    var problems2: [MAX_PROBLEMS]Problem = undefined;
    const parsed2 = parseWorksheetCephalopod(lines, max_width, &problems2);
    try stdout.print("Answer:  {}\n", .{solve(parsed2)});
}
