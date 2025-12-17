// Advent of Code 2025 - Day 11: Reactor (counting paths through a device network)
//
// Part 1: Count all paths from "you" to "out" in a DAG
// Part 2: Count paths from "svr" to "out" that pass through both "dac" and "fft"

const std = @import("std");

// graph maps device names to their output devices
// using []const u8 slices (pointing into the input buffer) to avoid allocations
const Graph = std.StringHashMap([][]const u8);

// cache key for memoization - (start, end) pair
const CacheKey = struct {
    start: []const u8,
    end: []const u8,
};

// Zig needs custom hash/eql functions for struct keys
const CacheContext = struct {
    pub fn hash(_: CacheContext, key: CacheKey) u64 {
        // combine hashes of both strings
        var h = std.hash.Wyhash.init(0);
        h.update(key.start);
        h.update(key.end);
        return h.final();
    }

    pub fn eql(_: CacheContext, a: CacheKey, b: CacheKey) bool {
        return std.mem.eql(u8, a.start, b.start) and std.mem.eql(u8, a.end, b.end);
    }
};

const Cache = std.HashMap(CacheKey, i64, CacheContext, std.hash_map.default_max_load_percentage);

// count paths from start to end, using memoization
fn countPaths(graph: *const Graph, cache: *Cache, start: []const u8, end: []const u8) i64 {
    // check cache first
    const key = CacheKey{ .start = start, .end = end };
    if (cache.get(key)) |count| {
        return count;
    }

    // base case: reached destination
    var result: i64 = undefined;
    if (std.mem.eql(u8, start, end)) {
        result = 1;
    } else if (graph.get(start)) |outputs| {
        // sum paths through all outputs
        result = 0;
        for (outputs) |next| {
            result += countPaths(graph, cache, next, end);
        }
    } else {
        // dead end: node doesn't exist or has no outputs
        result = 0;
    }

    cache.put(key, result) catch {};
    return result;
}

// count paths from start to end that visit both waypoints.
// multiplication principle: paths(A->B->C) = paths(A->B) * paths(B->C)
// in a DAG, either wp1 comes before wp2 or vice versa - one term will be zero.
fn countPathsThroughBoth(
    graph: *const Graph,
    cache: *Cache,
    start: []const u8,
    end: []const u8,
    wp1: []const u8,
    wp2: []const u8,
) i64 {
    // paths hitting wp1 first, then wp2
    const via_wp1_first = countPaths(graph, cache, start, wp1) *
        countPaths(graph, cache, wp1, wp2) *
        countPaths(graph, cache, wp2, end);

    // paths hitting wp2 first, then wp1
    const via_wp2_first = countPaths(graph, cache, start, wp2) *
        countPaths(graph, cache, wp2, wp1) *
        countPaths(graph, cache, wp1, end);

    return via_wp1_first + via_wp2_first;
}

pub fn main() !void {
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

    // parse graph - we store slices pointing into content (no string copies)
    var graph = Graph.init(allocator);
    defer {
        // free the output arrays we allocated
        var iter = graph.valueIterator();
        while (iter.next()) |outputs| {
            allocator.free(outputs.*);
        }
        graph.deinit();
    }

    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        // format: "device: output1 output2 output3"
        var parts = std.mem.splitSequence(u8, line, ": ");
        const device = parts.next() orelse continue;
        const outputs_str = parts.next() orelse "";

        // count outputs first to allocate exact size
        var output_count: usize = 0;
        var counter = std.mem.splitScalar(u8, outputs_str, ' ');
        while (counter.next()) |s| {
            if (s.len > 0) output_count += 1;
        }

        // allocate and fill outputs array
        const outputs = try allocator.alloc([]const u8, output_count);
        var idx: usize = 0;
        var splitter = std.mem.splitScalar(u8, outputs_str, ' ');
        while (splitter.next()) |s| {
            if (s.len > 0) {
                outputs[idx] = s;
                idx += 1;
            }
        }

        try graph.put(device, outputs);
    }

    // single cache shared across all queries
    var cache = Cache.init(allocator);
    defer cache.deinit();

    // Zig 0.15 stdout API
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    try stdout.print("--- Part 1 ---\n", .{});
    const part1 = countPaths(&graph, &cache, "you", "out");
    try stdout.print("Answer: {}\n", .{part1});

    try stdout.print("--- Part 2 ---\n", .{});
    const part2 = countPathsThroughBoth(&graph, &cache, "svr", "out", "dac", "fft");
    try stdout.print("Answer: {}\n", .{part2});
}
