// Advent of Code 2025 - Day 8: Playground (connecting junction boxes with Union-Find)
//
// Union-Find (Disjoint Set Union) connects 3D points by shortest distances.
// Part 1: connect 1000 shortest pairs, return product of 3 largest components
// Part 2: connect until one component (MST), return X1 * X2 of final edge

const std = @import("std");

const Point3D = struct {
    x: i64,
    y: i64,
    z: i64,
};

const Edge = struct {
    dist_sq: i64,
    i: usize,
    j: usize,
};

// Union-Find with path compression and union by rank
const UnionFind = struct {
    parent: []usize,
    rank: []usize,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, n: usize) !UnionFind {
        const parent = try allocator.alloc(usize, n);
        const rank = try allocator.alloc(usize, n);

        // each node starts as its own parent
        for (0..n) |i| {
            parent[i] = i;
            rank[i] = 0;
        }

        return UnionFind{
            .parent = parent,
            .rank = rank,
            .allocator = allocator,
        };
    }

    fn deinit(self: *UnionFind) void {
        self.allocator.free(self.parent);
        self.allocator.free(self.rank);
    }

    // find root with path compression (iterative)
    fn find(self: *UnionFind, x_param: usize) usize {
        var x = x_param;
        while (self.parent[x] != x) {
            x = self.parent[x];
        }
        const root = x;

        // path compression
        x = x_param;
        while (self.parent[x] != root) {
            const next = self.parent[x];
            self.parent[x] = root;
            x = next;
        }
        return root;
    }

    // union two sets, returns true if they were separate
    fn doUnion(self: *UnionFind, x: usize, y: usize) bool {
        const root_x = self.find(x);
        const root_y = self.find(y);

        if (root_x == root_y) {
            return false;
        }

        if (self.rank[root_x] < self.rank[root_y]) {
            self.parent[root_x] = root_y;
        } else if (self.rank[root_x] > self.rank[root_y]) {
            self.parent[root_y] = root_x;
        } else {
            self.parent[root_y] = root_x;
            self.rank[root_x] += 1;
        }
        return true;
    }

    // get top 3 component sizes (descending)
    fn getTop3Sizes(self: *UnionFind) [3]usize {
        const n = self.parent.len;

        // count per root - use a simple approach for small n
        var top3 = [3]usize{ 0, 0, 0 };

        for (0..n) |root_candidate| {
            var count: usize = 0;
            for (0..n) |i| {
                if (self.find(i) == root_candidate) {
                    count += 1;
                }
            }
            if (count > top3[0]) {
                top3[2] = top3[1];
                top3[1] = top3[0];
                top3[0] = count;
            } else if (count > top3[1]) {
                top3[2] = top3[1];
                top3[1] = count;
            } else if (count > top3[2]) {
                top3[2] = count;
            }
        }
        return top3;
    }
};

fn distanceSquared(a: Point3D, b: Point3D) i64 {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    const dz = a.z - b.z;
    return dx * dx + dy * dy + dz * dz;
}

fn edgeLessThan(_: void, a: Edge, b: Edge) bool {
    return a.dist_sq < b.dist_sq;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // buffered stdout
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};

    // load input
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    // count lines first to allocate exact size
    var line_count: usize = 0;
    var count_iter = std.mem.splitScalar(u8, content, '\n');
    while (count_iter.next()) |line| {
        if (line.len > 0) line_count += 1;
    }

    // allocate and parse points
    var points = try allocator.alloc(Point3D, line_count);
    defer allocator.free(points);

    var point_idx: usize = 0;
    var line_iter = std.mem.splitScalar(u8, content, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        const z = try std.fmt.parseInt(i64, parts.next().?, 10);

        points[point_idx] = Point3D{ .x = x, .y = y, .z = z };
        point_idx += 1;
    }

    const n = points.len;
    const num_edges = n * (n - 1) / 2;

    // generate all edges on heap
    var edges = try allocator.alloc(Edge, num_edges);
    defer allocator.free(edges);

    var edge_idx: usize = 0;
    for (0..n) |i| {
        for ((i + 1)..n) |j| {
            edges[edge_idx] = Edge{
                .dist_sq = distanceSquared(points[i], points[j]),
                .i = i,
                .j = j,
            };
            edge_idx += 1;
        }
    }

    // sort by distance
    std.mem.sort(Edge, edges, {}, edgeLessThan);

    // Part 1: connect 1000 shortest pairs
    try stdout.print("--- Part 1 ---\n", .{});

    var uf1 = try UnionFind.init(allocator, n);
    defer uf1.deinit();

    const to_connect = @min(1000, edges.len);
    for (0..to_connect) |k| {
        _ = uf1.doUnion(edges[k].i, edges[k].j);
    }

    const top3 = uf1.getTop3Sizes();
    const part1 = @as(i64, @intCast(top3[0])) * @as(i64, @intCast(top3[1])) * @as(i64, @intCast(top3[2]));
    try stdout.print("Answer: {}\n", .{part1});

    // Part 2: connect until one component (MST)
    try stdout.print("\n--- Part 2 ---\n", .{});

    var uf2 = try UnionFind.init(allocator, n);
    defer uf2.deinit();

    var unions_made: usize = 0;
    var last_i: usize = 0;
    var last_j: usize = 0;

    for (edges) |edge| {
        if (uf2.doUnion(edge.i, edge.j)) {
            unions_made += 1;
            last_i = edge.i;
            last_j = edge.j;
            if (unions_made == n - 1) {
                break;
            }
        }
    }

    const part2 = points[last_i].x * points[last_j].x;
    try stdout.print("Answer: {}\n", .{part2});
}
