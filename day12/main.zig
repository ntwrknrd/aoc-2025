// Advent of Code 2025 - Day 12: Christmas Tree Farm (polyomino packing)
//
// Part 1: Count how many regions can fit all their required shapes
//
// Zig makes memory management explicit - every allocation needs an allocator,
// and you're responsible for freeing memory. No garbage collector here!

const std = @import("std");
const Allocator = std.mem.Allocator;

// a cell is just a (row, col) coordinate
const Cell = struct {
    row: i32,
    col: i32,
};

// a shape is a slice of cells - we'll normalize so top-left is (0,0)
const Shape = []Cell;

// region holds dimensions and required shape counts
const Region = struct {
    width: usize,
    height: usize,
    counts: []usize,
};

// normalize shifts a shape so its top-left corner is at (0, 0)
fn normalize(allocator: Allocator, cells: []const Cell) !Shape {
    if (cells.len == 0) {
        return try allocator.alloc(Cell, 0);
    }

    // find min row and col
    var min_row: i32 = std.math.maxInt(i32);
    var min_col: i32 = std.math.maxInt(i32);
    for (cells) |cell| {
        if (cell.row < min_row) min_row = cell.row;
        if (cell.col < min_col) min_col = cell.col;
    }

    // shift everything
    const result = try allocator.alloc(Cell, cells.len);
    for (cells, 0..) |cell, i| {
        result[i] = Cell{
            .row = cell.row - min_row,
            .col = cell.col - min_col,
        };
    }

    // sort for consistent comparison (simple insertion sort - shapes are tiny)
    for (1..result.len) |i| {
        const key = result[i];
        var j: usize = i;
        while (j > 0 and cellLessThan(key, result[j - 1])) {
            result[j] = result[j - 1];
            j -= 1;
        }
        result[j] = key;
    }

    return result;
}

fn cellLessThan(a: Cell, b: Cell) bool {
    if (a.row != b.row) return a.row < b.row;
    return a.col < b.col;
}

// rotate 90 degrees clockwise: (r, c) -> (c, -r)
fn rotate90(allocator: Allocator, shape: Shape) !Shape {
    const rotated = try allocator.alloc(Cell, shape.len);
    for (shape, 0..) |cell, i| {
        rotated[i] = Cell{ .row = cell.col, .col = -cell.row };
    }
    const normalized = try normalize(allocator, rotated);
    allocator.free(rotated);
    return normalized;
}

// flip horizontally: (r, c) -> (r, -c)
fn flipHorizontal(allocator: Allocator, shape: Shape) !Shape {
    const flipped = try allocator.alloc(Cell, shape.len);
    for (shape, 0..) |cell, i| {
        flipped[i] = Cell{ .row = cell.row, .col = -cell.col };
    }
    const normalized = try normalize(allocator, flipped);
    allocator.free(flipped);
    return normalized;
}

// check if two shapes are identical (assumes both are normalized and sorted)
fn shapesEqual(a: Shape, b: Shape) bool {
    if (a.len != b.len) return false;
    for (a, b) |ca, cb| {
        if (ca.row != cb.row or ca.col != cb.col) return false;
    }
    return true;
}

// check if shape is already in the list
fn containsShape(shapes: []const Shape, shape: Shape) bool {
    for (shapes) |s| {
        if (shapesEqual(s, shape)) return true;
    }
    return false;
}

// get all unique orientations (up to 8) of a shape
// Zig 0.15 uses ArrayListUnmanaged - we pass allocator to each method
fn getAllOrientations(allocator: Allocator, shape: Shape) ![]Shape {
    var orientations = std.ArrayListUnmanaged(Shape){};

    var current = try normalize(allocator, shape);

    for (0..4) |_| {
        // try normal and flipped versions
        const flipped = try flipHorizontal(allocator, current);

        for ([_]Shape{ current, flipped }) |s| {
            if (!containsShape(orientations.items, s)) {
                const copy = try allocator.dupe(Cell, s);
                try orientations.append(allocator, copy);
            }
        }

        // only free flipped if it wasn't added
        if (!containsShape(orientations.items, flipped)) {
            allocator.free(flipped);
        }

        const next = try rotate90(allocator, current);
        // free current unless it was added to orientations
        if (!containsShape(orientations.items, current)) {
            allocator.free(current);
        }
        current = next;
    }

    // free last rotation if not used
    if (!containsShape(orientations.items, current)) {
        allocator.free(current);
    }

    return orientations.toOwnedSlice(allocator);
}

// grid tracks which cells are occupied
const Grid = struct {
    cells: [][]bool,
    height: usize,
    width: usize,
    allocator: Allocator,

    fn init(allocator: Allocator, height: usize, width: usize) !Grid {
        const cells = try allocator.alloc([]bool, height);
        for (cells) |*row| {
            row.* = try allocator.alloc(bool, width);
            @memset(row.*, false);
        }
        return Grid{ .cells = cells, .height = height, .width = width, .allocator = allocator };
    }

    fn deinit(self: *Grid) void {
        for (self.cells) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.cells);
    }

    fn canPlace(self: *const Grid, shape: Shape, start_row: i32, start_col: i32) bool {
        for (shape) |cell| {
            const r = start_row + cell.row;
            const c = start_col + cell.col;

            if (r < 0 or r >= @as(i32, @intCast(self.height)) or
                c < 0 or c >= @as(i32, @intCast(self.width)))
            {
                return false;
            }
            if (self.cells[@intCast(r)][@intCast(c)]) {
                return false;
            }
        }
        return true;
    }

    fn place(self: *Grid, shape: Shape, start_row: i32, start_col: i32, fill: bool) void {
        for (shape) |cell| {
            const r: usize = @intCast(start_row + cell.row);
            const c: usize = @intCast(start_col + cell.col);
            self.cells[r][c] = fill;
        }
    }
};

// backtracking to place all shapes
fn canPlaceAll(to_place: []const []const Shape, grid: *Grid) bool {
    if (to_place.len == 0) return true;

    const orientations = to_place[0];
    const remaining = to_place[1..];

    // try each orientation at each position
    for (orientations) |orientation| {
        var row: i32 = 0;
        while (row < @as(i32, @intCast(grid.height))) : (row += 1) {
            var col: i32 = 0;
            while (col < @as(i32, @intCast(grid.width))) : (col += 1) {
                if (grid.canPlace(orientation, row, col)) {
                    grid.place(orientation, row, col, true);

                    if (canPlaceAll(remaining, grid)) {
                        return true;
                    }

                    // backtrack
                    grid.place(orientation, row, col, false);
                }
            }
        }
    }

    return false;
}

fn canFitRegion(allocator: Allocator, shapes: []const []const Shape, region: Region) !bool {
    // quick check: enough cells?
    var total_cells: usize = 0;
    for (region.counts, 0..) |count, idx| {
        if (count > 0 and idx < shapes.len and shapes[idx].len > 0) {
            total_cells += count * shapes[idx][0].len;
        }
    }

    if (total_cells > region.width * region.height) {
        return false;
    }

    // build list of shape orientations to place
    var to_place = std.ArrayListUnmanaged([]const Shape){};
    defer to_place.deinit(allocator);

    for (region.counts, 0..) |count, idx| {
        if (idx < shapes.len) {
            for (0..count) |_| {
                try to_place.append(allocator, shapes[idx]);
            }
        }
    }

    var grid = try Grid.init(allocator, region.height, region.width);
    defer grid.deinit();

    return canPlaceAll(to_place.items, &grid);
}

pub fn main() !void {
    // arena allocator is perfect for AoC - allocate everything, free all at once
    // no need to track individual allocations, just free the arena at the end
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    // load input
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    _ = try file.readAll(content);

    // parse shapes and regions
    // with arena allocator, no need for manual cleanup - arena.deinit() frees everything
    var shapes = std.ArrayListUnmanaged([]Shape){};
    var regions = std.ArrayListUnmanaged(Region){};

    // split into sections by double newline
    var sections = std.mem.splitSequence(u8, content, "\n\n");
    while (sections.next()) |section| {
        if (section.len == 0) continue;

        var lines = std.mem.splitScalar(u8, section, '\n');
        const first_line = lines.next() orelse continue;

        // shape definition: ends with ':'
        if (first_line.len > 0 and first_line[first_line.len - 1] == ':') {
            const idx_str = first_line[0 .. first_line.len - 1];
            const idx = std.fmt.parseInt(usize, idx_str, 10) catch continue;

            // collect shape cells
            var cells = std.ArrayListUnmanaged(Cell){};

            var row: i32 = 0;
            while (lines.next()) |line| {
                for (line, 0..) |ch, col| {
                    if (ch == '#') {
                        try cells.append(allocator, Cell{ .row = row, .col = @intCast(col) });
                    }
                }
                row += 1;
            }

            // ensure shapes array is big enough
            while (shapes.items.len <= idx) {
                try shapes.append(allocator, try allocator.alloc(Shape, 0));
            }

            // free old orientations if any
            for (shapes.items[idx]) |shape| {
                allocator.free(shape);
            }
            allocator.free(shapes.items[idx]);

            shapes.items[idx] = try getAllOrientations(allocator, cells.items);
            continue;
        }

        // region definitions: contain 'x'
        var region_lines = std.mem.splitScalar(u8, section, '\n');
        while (region_lines.next()) |line| {
            if (std.mem.indexOf(u8, line, "x") == null) continue;
            if (std.mem.indexOf(u8, line, ": ") == null) continue;

            var parts = std.mem.splitSequence(u8, line, ": ");
            const dims_str = parts.next() orelse continue;
            const counts_str = parts.next() orelse continue;

            var dims = std.mem.splitScalar(u8, dims_str, 'x');
            const width = std.fmt.parseInt(usize, dims.next() orelse continue, 10) catch continue;
            const height = std.fmt.parseInt(usize, dims.next() orelse continue, 10) catch continue;

            // parse counts
            var counts_list = std.ArrayListUnmanaged(usize){};
            var count_parts = std.mem.splitScalar(u8, counts_str, ' ');
            while (count_parts.next()) |s| {
                if (s.len > 0) {
                    const count = std.fmt.parseInt(usize, s, 10) catch continue;
                    try counts_list.append(allocator, count);
                }
            }

            try regions.append(allocator, Region{
                .width = width,
                .height = height,
                .counts = try counts_list.toOwnedSlice(allocator),
            });
        }
    }

    // Part 1: count regions that can fit all their presents
    var count: usize = 0;
    for (regions.items) |region| {
        if (try canFitRegion(allocator, shapes.items, region)) {
            count += 1;
        }
    }

    // Zig 0.15 stdout API
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    try stdout.print("Part 1: {}\n", .{count});
}
