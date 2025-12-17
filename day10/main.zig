// Advent of Code 2025 - Day 10: Factory (toggling lights & joltage counters)
//
// Part 1: Toggle lights with buttons to match a target pattern. Since toggling
// twice cancels out (XOR), each button is pressed 0 or 1 times optimally.
//
// Part 2: Counters that accumulate - buttons can be pressed multiple times.
// This becomes an Integer Linear Programming problem. We use Apple's Accelerate
// framework (LAPACK) to solve linear systems - a cool example of Zig's C interop!

const std = @import("std");

// LAPACK functions from Apple's Accelerate framework
// Note: LAPACK uses Fortran conventions - column-major and pass-by-pointer

// dgesv_ solves Ax = B for square systems using LU decomposition
extern "c" fn dgesv_(
    n: *c_int, // number of linear equations
    nrhs: *c_int, // number of right-hand sides (columns of B)
    a: [*]f64, // matrix A (n x n), overwritten with L and U
    lda: *c_int, // leading dimension of A
    ipiv: [*]c_int, // pivot indices from partial pivoting
    b: [*]f64, // right-hand side B, overwritten with solution X
    ldb: *c_int, // leading dimension of B
    info: *c_int, // 0 = success, <0 = bad arg, >0 = singular matrix
) void;

// dgels_ solves overdetermined/underdetermined systems using QR/LQ factorization
extern "c" fn dgels_(
    trans: *const u8, // 'N' = no transpose (solve Ax = b)
    m: *c_int, // rows of A (number of equations)
    n: *c_int, // columns of A (number of variables)
    nrhs: *c_int, // number of right-hand sides
    a: [*]f64, // m x n matrix, overwritten
    lda: *c_int, // leading dimension of A
    b: [*]f64, // max(m,n) x nrhs, overwritten with solution
    ldb: *c_int, // leading dimension of B
    work: [*]f64, // workspace
    lwork: *c_int, // size of workspace (-1 for query)
    info: *c_int, // status
) void;

const Machine = struct {
    target: []bool, // goal light state (true = on)
    buttons: [][]u32, // each button lists which indices it affects
    joltages: []i32, // target counter values for part 2
    allocator: std.mem.Allocator,

    fn deinit(self: *Machine) void {
        self.allocator.free(self.target);
        for (self.buttons) |btn| {
            self.allocator.free(btn);
        }
        self.allocator.free(self.buttons);
        self.allocator.free(self.joltages);
    }
};

// count occurrences of a character in a slice
fn countChar(s: []const u8, c: u8) usize {
    var count: usize = 0;
    for (s) |ch| {
        if (ch == c) count += 1;
    }
    return count;
}

// parse a line like: [.##.] (3) (1,3) (2) {3,5,4,7}
fn parseLine(line: []const u8, allocator: std.mem.Allocator) !Machine {
    // count elements first to pre-allocate (Zig's approach - avoid dynamic resizing)
    var num_buttons: usize = 0;
    var num_joltages: usize = 0;
    var num_lights: usize = 0;

    // find the light pattern bounds
    var light_start: usize = 0;
    var light_end: usize = 0;
    for (line, 0..) |c, idx| {
        if (c == '[') light_start = idx + 1;
        if (c == ']') light_end = idx;
    }
    num_lights = light_end - light_start;

    // count buttons (number of '(' characters)
    num_buttons = countChar(line, '(');

    // count joltages (find {...} and count commas + 1)
    for (line, 0..) |c, idx| {
        if (c == '{') {
            var j = idx + 1;
            while (j < line.len and line[j] != '}') : (j += 1) {
                if (line[j] == ',') num_joltages += 1;
            }
            num_joltages += 1; // one more than commas
            break;
        }
    }

    // allocate arrays
    const target = try allocator.alloc(bool, num_lights);
    const buttons = try allocator.alloc([]u32, num_buttons);
    const joltages = try allocator.alloc(i32, num_joltages);

    // parse target lights
    for (line[light_start..light_end], 0..) |c, idx| {
        target[idx] = (c == '#');
    }

    // parse buttons
    var btn_idx: usize = 0;
    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '(') {
            i += 1;
            // count indices in this button first
            var num_indices: usize = 0;
            var j = i;
            while (j < line.len and line[j] != ')') : (j += 1) {
                if (line[j] == ',') num_indices += 1;
            }
            num_indices += 1;

            const indices = try allocator.alloc(u32, num_indices);
            var idx_pos: usize = 0;

            while (i < line.len and line[i] != ')') {
                if (line[i] == ',') {
                    i += 1;
                    continue;
                }
                var num: u32 = 0;
                while (i < line.len and line[i] >= '0' and line[i] <= '9') {
                    num = num * 10 + (line[i] - '0');
                    i += 1;
                }
                indices[idx_pos] = num;
                idx_pos += 1;
            }
            buttons[btn_idx] = indices;
            btn_idx += 1;
        }
    }

    // parse joltages
    var jolt_idx: usize = 0;
    i = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '{') {
            i += 1;
            while (i < line.len and line[i] != '}') {
                if (line[i] == ',') {
                    i += 1;
                    continue;
                }
                var num: i32 = 0;
                while (i < line.len and line[i] >= '0' and line[i] <= '9') {
                    num = num * 10 + @as(i32, @intCast(line[i] - '0'));
                    i += 1;
                }
                joltages[jolt_idx] = num;
                jolt_idx += 1;
            }
            break;
        }
    }

    return Machine{
        .target = target,
        .buttons = buttons,
        .joltages = joltages,
        .allocator = allocator,
    };
}

// Part 1: brute force all 2^n button combinations
// since toggling twice cancels, each button is pressed 0 or 1 times
fn findMinPresses(m: *const Machine, allocator: std.mem.Allocator) !i32 {
    const num_buttons = m.buttons.len;
    const num_lights = m.target.len;

    if (num_buttons > 20) return -1; // safety limit

    // allocate state buffer once
    const state = try allocator.alloc(bool, num_lights);
    defer allocator.free(state);

    const total: u32 = @as(u32, 1) << @intCast(num_buttons);

    // try subsets from smallest (0 buttons) to largest
    for (0..num_buttons + 1) |target_count| {
        var mask: u32 = 0;
        while (mask < total) : (mask += 1) {
            // @popCount gives number of 1-bits in the mask
            if (@popCount(mask) != target_count) continue;

            // reset state to all off
            @memset(state, false);

            // apply each button in the mask
            for (m.buttons, 0..) |btn, btn_idx| {
                if (mask & (@as(u32, 1) << @intCast(btn_idx)) != 0) {
                    for (btn) |light| {
                        if (light < num_lights) {
                            state[light] = !state[light];
                        }
                    }
                }
            }

            // check if we match target
            if (std.mem.eql(bool, state, m.target)) {
                return @intCast(target_count);
            }
        }
    }

    return -1;
}

fn solvePart1(machines: []Machine, allocator: std.mem.Allocator) !i32 {
    var total: i32 = 0;
    for (machines) |*m| {
        total += try findMinPresses(m, allocator);
    }
    return total;
}

// --- Part 2: Integer Linear Programming with LAPACK ---

// check if a float is close to a non-negative integer
fn isNonNegInt(x: f64) ?i32 {
    // guard against NaN, infinity, and out-of-range values
    if (std.math.isNan(x) or std.math.isInf(x)) return null;
    if (x < -1e-6) return null;
    if (x > 2147483647.0) return null; // max i32

    const rounded_f = @round(x);
    if (@abs(x - rounded_f) > 1e-6) return null;

    const rounded = @as(i32, @intFromFloat(rounded_f));
    if (rounded < 0) return null;
    return rounded;
}

// recursive combination generator
fn genCombos(
    n: usize,
    k: usize,
    start: usize,
    idx: usize,
    combo: []usize,
    result: *std.ArrayListUnmanaged([]usize),
    allocator: std.mem.Allocator,
) !void {
    if (idx == k) {
        const copy = try allocator.alloc(usize, k);
        @memcpy(copy, combo);
        try result.append(allocator, copy);
        return;
    }

    var i = start;
    while (i <= n - (k - idx)) : (i += 1) {
        combo[idx] = i;
        try genCombos(n, k, i + 1, idx + 1, combo, result, allocator);
    }
}

fn getCombinations(n: usize, k: usize, allocator: std.mem.Allocator) ![][]usize {
    if (k > n or k == 0) return &[_][]usize{};

    var result = std.ArrayListUnmanaged([]usize){};
    const combo = try allocator.alloc(usize, k);
    defer allocator.free(combo);

    try genCombos(n, k, 0, 0, combo, &result, allocator);

    return result.toOwnedSlice(allocator);
}

// solve Ax = b using LAPACK's dgels (least squares), handles non-square matrices
// a_data: m x n matrix (m rows/equations, n cols/variables) in column-major
// b_data: m x 1 right-hand side
// returns n-element solution if all non-negative integers
fn solveLinearSystemRect(
    a_data: []const f64,
    b_data: []const f64,
    m: usize, // rows (equations/counters)
    n: usize, // cols (variables/buttons in subset)
    allocator: std.mem.Allocator,
) !?[]i32 {
    if (m == 0 or n == 0) return null;

    // use fixed-size stack buffers - avoids allocation and LAPACK workspace query
    // our matrices are small (max ~10x10), so 1024 is plenty for workspace
    var a: [400]f64 = undefined; // 20x20 max
    var b: [20]f64 = undefined;
    var work: [1024]f64 = undefined;

    @memcpy(a[0 .. m * n], a_data);

    const b_len = @max(m, n);
    @memset(b[0..b_len], 0.0);
    @memcpy(b[0..m], b_data);

    var m_int: c_int = @intCast(m);
    var n_int: c_int = @intCast(n);
    var nrhs: c_int = 1;
    var lda: c_int = @intCast(m);
    var ldb: c_int = @intCast(b_len);
    var info: c_int = 0;
    var lwork: c_int = 1024;
    const trans: u8 = 'N';

    dgels_(&trans, &m_int, &n_int, &nrhs, &a, &lda, &b, &ldb, &work, &lwork, &info);

    if (info != 0) return null;

    // for overdetermined (m > n), check residual is ~0
    if (m > n) {
        var residual: f64 = 0;
        // dgels puts residual in b[n..m]
        for (b[n..m]) |r| {
            residual += r * r;
        }
        if (residual > 1e-6) return null; // not an exact solution
    }

    // solution is in first n elements of b
    const solution = try allocator.alloc(i32, n);
    for (b[0..n], 0..) |val, i| {
        if (isNonNegInt(val)) |int_val| {
            solution[i] = int_val;
        } else {
            allocator.free(solution);
            return null;
        }
    }

    return solution;
}

// wrapper for square systems (backward compat)
fn solveLinearSystem(
    a_data: []const f64,
    b_data: []const f64,
    n: usize,
    allocator: std.mem.Allocator,
) !?[]i32 {
    return solveLinearSystemRect(a_data, b_data, n, n, allocator);
}

// verify solution: does pressing these buttons produce the target joltages?
fn verifySolution(
    joltages: []const i32,
    buttons: []const []u32,
    subset: []const usize,
    presses: []const i32,
) bool {
    for (joltages, 0..) |target, counter| {
        var sum: i32 = 0;
        for (subset, 0..) |btn_idx, i| {
            for (buttons[btn_idx]) |affected| {
                if (affected == counter) {
                    sum += presses[i];
                    break;
                }
            }
        }
        if (sum != target) return false;
    }
    return true;
}

// solve system with one free variable analytically
// returns minimum total presses if valid solution exists
fn solveOneFreeVar(
    m: *const Machine,
    subset: []const usize,
    free_idx: usize,
    allocator: std.mem.Allocator,
) !?i32 {
    const n = m.joltages.len;
    if (subset.len != n + 1) return null;

    // build basic (non-free) indices
    const basic_idx = try allocator.alloc(usize, n);
    defer allocator.free(basic_idx);
    var bi: usize = 0;
    for (0..subset.len) |i| {
        if (i != free_idx) {
            basic_idx[bi] = i;
            bi += 1;
        }
    }

    // build matrix for basic variables (column-major)
    const basic_a = try allocator.alloc(f64, n * n);
    defer allocator.free(basic_a);
    @memset(basic_a, 0.0);

    for (basic_idx, 0..) |idx, col| {
        const btn = subset[idx];
        for (m.buttons[btn]) |counter| {
            if (counter < n) {
                basic_a[counter + col * n] = 1.0;
            }
        }
    }

    // build b vector
    const b = try allocator.alloc(f64, n);
    defer allocator.free(b);
    for (m.joltages, 0..) |j, i| {
        b[i] = @floatFromInt(j);
    }

    // solve for x0 (solution when free var = 0)
    const x0 = try allocator.alloc(f64, n);
    defer allocator.free(x0);
    @memcpy(x0, b);

    const a_copy = try allocator.alloc(f64, n * n);
    defer allocator.free(a_copy);
    @memcpy(a_copy, basic_a);

    const ipiv = try allocator.alloc(c_int, n);
    defer allocator.free(ipiv);

    var n_int: c_int = @intCast(n);
    var nrhs: c_int = 1;
    var info: c_int = 0;

    dgesv_(&n_int, &nrhs, a_copy.ptr, &n_int, ipiv.ptr, x0.ptr, &n_int, &info);
    if (info != 0) return null;

    // build free column vector (what the free button affects)
    const free_col = try allocator.alloc(f64, n);
    defer allocator.free(free_col);
    @memset(free_col, 0.0);

    const free_btn = subset[free_idx];
    for (m.buttons[free_btn]) |counter| {
        if (counter < n) {
            free_col[counter] = 1.0;
        }
    }

    // solve for coef: how basic vars change with t (coef = A^-1 * free_col)
    const coef = try allocator.alloc(f64, n);
    defer allocator.free(coef);
    @memcpy(coef, free_col);

    @memcpy(a_copy, basic_a);
    info = 0;
    dgesv_(&n_int, &nrhs, a_copy.ptr, &n_int, ipiv.ptr, coef.ptr, &n_int, &info);
    if (info != 0) return null;

    // find valid range for t: x_basic = x0 - coef*t >= 0
    var t_min: f64 = 0.0;
    var t_max: f64 = 1e9;

    for (0..n) |i| {
        const c = coef[i];
        const x = x0[i];
        if (c > 1e-9) {
            t_max = @min(t_max, x / c);
        } else if (c < -1e-9) {
            t_min = @max(t_min, x / c);
        } else if (x < -1e-9) {
            return null; // infeasible
        }
    }

    if (t_min > t_max + 1e-9) return null;

    // total = sum(x0) + (1 - sum(coef)) * t, find optimal integer t
    var sum_coef: f64 = 0;
    for (coef) |c| sum_coef += c;
    const slope = 1.0 - sum_coef;

    var opt_t: i32 = undefined;
    if (slope > 1e-9) {
        opt_t = @intFromFloat(@ceil(t_min));
    } else if (slope < -1e-9) {
        opt_t = @intFromFloat(@floor(t_max));
    } else {
        opt_t = @intFromFloat(@ceil(t_min));
    }

    // clamp to valid range
    if (@as(f64, @floatFromInt(opt_t)) < t_min - 1e-9) {
        opt_t = @intFromFloat(@ceil(t_min));
    }
    if (@as(f64, @floatFromInt(opt_t)) > t_max + 1e-9) {
        opt_t = @intFromFloat(@floor(t_max));
    }
    if (opt_t < 0) return null;

    // build and verify solution
    const full_solution = try allocator.alloc(i32, subset.len);
    defer allocator.free(full_solution);

    var si: usize = 0;
    for (0..subset.len) |i| {
        if (i == free_idx) {
            full_solution[i] = opt_t;
        } else {
            const val = x0[si] - coef[si] * @as(f64, @floatFromInt(opt_t));
            if (isNonNegInt(val)) |int_val| {
                full_solution[i] = int_val;
            } else {
                return null;
            }
            si += 1;
        }
    }

    if (!verifySolution(m.joltages, m.buttons, subset, full_solution)) {
        return null;
    }

    var total: i32 = 0;
    for (full_solution) |p| total += p;
    return total;
}

// solve with two free vars: fix first, solve second analytically
fn solveTwoFreeVars(
    m: *const Machine,
    subset: []const usize,
    free_idx1: usize,
    free_idx2: usize,
    fv1: i32,
    allocator: std.mem.Allocator,
) !?i32 {
    const n = m.joltages.len;

    // adjust joltages for first free var
    const adj_joltages = try allocator.alloc(i32, n);
    defer allocator.free(adj_joltages);

    const free_btn1 = subset[free_idx1];
    for (m.joltages, 0..) |j, counter| {
        var contrib: i32 = 0;
        for (m.buttons[free_btn1]) |affected| {
            if (affected == counter) {
                contrib = fv1;
                break;
            }
        }
        adj_joltages[counter] = j - contrib;
        if (adj_joltages[counter] < 0) return null;
    }

    // build reduced subset (excluding first free var)
    const reduced_subset = try allocator.alloc(usize, subset.len - 1);
    defer allocator.free(reduced_subset);

    var ri: usize = 0;
    var new_free_idx: usize = 0;
    for (subset, 0..) |btn, i| {
        if (i != free_idx1) {
            if (i == free_idx2) new_free_idx = ri;
            reduced_subset[ri] = btn;
            ri += 1;
        }
    }

    // create temp machine with adjusted joltages
    var temp_m = m.*;
    temp_m.joltages = adj_joltages;

    // solve with one free var
    if (try solveOneFreeVar(&temp_m, reduced_subset, new_free_idx, allocator)) |sub_total| {
        return sub_total + fv1;
    }
    return null;
}

// try solving a square system with the given subset of buttons
fn trySolveSubset(
    m: *const Machine,
    subset: []const usize,
    allocator: std.mem.Allocator,
) !?i32 {
    const n = m.joltages.len;
    if (subset.len != n) return null;

    // build incidence matrix A in column-major order
    const a = try allocator.alloc(f64, n * n);
    defer allocator.free(a);
    @memset(a, 0.0);

    for (subset, 0..) |btn_idx, col| {
        for (m.buttons[btn_idx]) |counter| {
            if (counter < n) {
                a[counter + col * n] = 1.0;
            }
        }
    }

    // build right-hand side vector b
    const b = try allocator.alloc(f64, n);
    defer allocator.free(b);
    for (m.joltages, 0..) |j, idx| {
        b[idx] = @floatFromInt(j);
    }

    // solve and check
    if (try solveLinearSystem(a, b, n, allocator)) |solution| {
        defer allocator.free(solution);
        if (verifySolution(m.joltages, m.buttons, subset, solution)) {
            var total: i32 = 0;
            for (solution) |presses| total += presses;
            return total;
        }
    }
    return null;
}

// find minimum button presses to reach exact joltage values using linear algebra
fn findMinJoltagePresses(m: *const Machine, allocator: std.mem.Allocator) !i32 {
    const num_buttons = m.buttons.len;
    const num_counters = m.joltages.len;

    if (num_buttons == 0 or num_counters == 0) return 0;

    var best: i32 = std.math.maxInt(i32);

    // find max joltage for bounding free variable search
    var max_jolt: i32 = 0;
    for (m.joltages) |j| {
        if (j > max_jolt) max_jolt = j;
    }

    // try subsets of size 1 to num_counters (square and overdetermined systems)
    const max_size = @min(num_counters, num_buttons);
    for (1..max_size + 1) |size| {
        const combos = try getCombinations(num_buttons, size, allocator);
        defer {
            for (combos) |combo| allocator.free(combo);
            allocator.free(combos);
        }

        for (combos) |subset| {
            // build m x n matrix (m = num_counters equations, n = size variables)
            const a = try allocator.alloc(f64, num_counters * size);
            defer allocator.free(a);
            @memset(a, 0.0);

            for (subset, 0..) |btn_idx, col| {
                for (m.buttons[btn_idx]) |counter| {
                    if (counter < num_counters) {
                        a[counter + col * num_counters] = 1.0;
                    }
                }
            }

            const b = try allocator.alloc(f64, num_counters);
            defer allocator.free(b);
            for (m.joltages, 0..) |j, i| {
                b[i] = @floatFromInt(j);
            }

            if (try solveLinearSystemRect(a, b, num_counters, size, allocator)) |solution| {
                defer allocator.free(solution);
                if (verifySolution(m.joltages, m.buttons, subset, solution)) {
                    var total: i32 = 0;
                    for (solution) |p| total += p;
                    if (total < best) best = total;
                }
            }
        }
    }

    // try subsets of size num_counters + 1 (one free variable)
    // use analytical approach: solve for optimal t value directly
    if (num_buttons > num_counters) {
        const combos = try getCombinations(num_buttons, num_counters + 1, allocator);
        defer {
            for (combos) |combo| allocator.free(combo);
            allocator.free(combos);
        }

        for (combos) |subset| {
            // try each button as the free variable
            for (0..subset.len) |free_idx| {
                if (try solveOneFreeVar(m, subset, free_idx, allocator)) |total| {
                    if (total < best) best = total;
                }
            }
        }
    }

    // try subsets of size num_counters + 2 (two free variables)
    // enumerate first free var (small range), solve second analytically
    if (num_buttons > num_counters + 1) {
        const combos = try getCombinations(num_buttons, num_counters + 2, allocator);
        defer {
            for (combos) |combo| allocator.free(combo);
            allocator.free(combos);
        }

        for (combos) |subset| {
            for (0..subset.len) |free_idx1| {
                for (free_idx1 + 1..subset.len) |free_idx2| {
                    // enumerate first free var in small range
                    const cap: i32 = @min(max_jolt, 30);
                    var fv1: i32 = 0;
                    while (fv1 <= cap) : (fv1 += 1) {
                        if (try solveTwoFreeVars(m, subset, free_idx1, free_idx2, fv1, allocator)) |total| {
                            if (total < best) best = total;
                        }
                    }
                }
            }
        }
    }

    if (best == std.math.maxInt(i32)) return -1;
    return best;
}

fn solvePart2(machines: []Machine, allocator: std.mem.Allocator) !i32 {
    var total: i32 = 0;
    for (machines) |*m| {
        total += try findMinJoltagePresses(m, allocator);
    }
    return total;
}

pub fn main() !void {
    // use the C allocator for speed - GPA has overhead even in release mode
    // (GPA is great for debugging memory issues, but we want raw speed here)
    const allocator = std.heap.c_allocator;

    // load input
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    // count lines
    var line_count: usize = 0;
    var count_iter = std.mem.splitScalar(u8, content, '\n');
    while (count_iter.next()) |line| {
        if (line.len > 0) line_count += 1;
    }

    // parse machines
    const machines = try allocator.alloc(Machine, line_count);
    defer {
        for (machines) |*m| m.deinit();
        allocator.free(machines);
    }

    var idx: usize = 0;
    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;
        machines[idx] = try parseLine(line, allocator);
        idx += 1;
    }

    // Zig 0.15 uses std.fs.File.stdout() with a buffer
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    try stdout.print("--- Part 1 ---\n", .{});
    const part1 = try solvePart1(machines, allocator);
    try stdout.print("Answer: {}\n", .{part1});

    try stdout.print("--- Part 2 ---\n", .{});
    const part2 = try solvePart2(machines, allocator);
    try stdout.print("Answer: {}\n", .{part2});
}
