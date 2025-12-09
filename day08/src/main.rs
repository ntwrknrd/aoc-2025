// Advent of Code 2025 - Day 8: Playground (connecting junction boxes with Union-Find)
//
// Union-Find (Disjoint Set Union) connects 3D points by shortest distances.
// Part 1: connect 1000 shortest pairs, return product of 3 largest components
// Part 2: connect until one component (MST), return X1 * X2 of final edge

use std::collections::HashMap;
use std::fs;

// Union-Find with path compression and union by rank
struct UnionFind {
    parent: Vec<usize>,
    rank: Vec<usize>,
}

impl UnionFind {
    fn new(n: usize) -> Self {
        // each node starts as its own parent (its own set)
        let parent = (0..n).collect();
        let rank = vec![0; n];
        UnionFind { parent, rank }
    }

    // find root with path compression
    fn find(&mut self, x: usize) -> usize {
        if self.parent[x] != x {
            // path compression: point directly to root
            self.parent[x] = self.find(self.parent[x]);
        }
        self.parent[x]
    }

    // union two sets, returns true if they were separate
    fn union(&mut self, x: usize, y: usize) -> bool {
        let root_x = self.find(x);
        let root_y = self.find(y);

        if root_x == root_y {
            return false; // already in same set
        }

        // union by rank: attach smaller tree under larger
        match self.rank[root_x].cmp(&self.rank[root_y]) {
            std::cmp::Ordering::Less => self.parent[root_x] = root_y,
            std::cmp::Ordering::Greater => self.parent[root_y] = root_x,
            std::cmp::Ordering::Equal => {
                self.parent[root_y] = root_x;
                self.rank[root_x] += 1;
            }
        }
        true
    }

    // get sizes of all connected components
    fn get_component_sizes(&mut self) -> Vec<usize> {
        let mut counts: HashMap<usize, usize> = HashMap::new();
        for i in 0..self.parent.len() {
            let root = self.find(i);
            *counts.entry(root).or_insert(0) += 1;
        }
        counts.values().copied().collect()
    }
}

#[derive(Clone, Copy)]
struct Point3D {
    x: i64,
    y: i64,
    z: i64,
}

// squared distance avoids sqrt - doesn't affect ordering
fn distance_squared(a: Point3D, b: Point3D) -> i64 {
    let dx = a.x - b.x;
    let dy = a.y - b.y;
    let dz = a.z - b.z;
    dx * dx + dy * dy + dz * dz
}

// Part 1: connect num_connections shortest pairs, product of 3 largest
fn solve(points: &[Point3D], num_connections: usize) -> i64 {
    let n = points.len();

    // generate all pairs with distances
    let mut edges: Vec<(i64, usize, usize)> = Vec::new();
    for i in 0..n {
        for j in (i + 1)..n {
            let dist_sq = distance_squared(points[i], points[j]);
            edges.push((dist_sq, i, j));
        }
    }

    // sort by distance
    edges.sort_by_key(|e| e.0);

    // connect shortest pairs
    let mut uf = UnionFind::new(n);
    for &(_, i, j) in edges.iter().take(num_connections) {
        uf.union(i, j);
    }

    // find 3 largest components
    let mut sizes = uf.get_component_sizes();
    sizes.sort_by(|a, b| b.cmp(a)); // descending

    (sizes[0] as i64) * (sizes[1] as i64) * (sizes[2] as i64)
}

// Part 2: connect until one component (MST), return X1 * X2 of final edge
fn solve_part2(points: &[Point3D]) -> i64 {
    let n = points.len();

    let mut edges: Vec<(i64, usize, usize)> = Vec::new();
    for i in 0..n {
        for j in (i + 1)..n {
            let dist_sq = distance_squared(points[i], points[j]);
            edges.push((dist_sq, i, j));
        }
    }

    edges.sort_by_key(|e| e.0);

    // Kruskal's MST - connect until we have one component
    let mut uf = UnionFind::new(n);
    let mut unions_made = 0;
    let mut last_i = 0;
    let mut last_j = 0;

    for &(_, i, j) in &edges {
        if uf.union(i, j) {
            unions_made += 1;
            last_i = i;
            last_j = j;
            // MST of n nodes has exactly n-1 edges
            if unions_made == n - 1 {
                break;
            }
        }
    }

    points[last_i].x * points[last_j].x
}

fn load_input(filename: &str) -> Vec<Point3D> {
    let content = fs::read_to_string(filename).expect("couldn't read file");
    content
        .lines()
        .filter(|line| !line.is_empty())
        .map(|line| {
            // parse "x,y,z" format
            let parts: Vec<i64> = line.split(',').map(|s| s.parse().unwrap()).collect();
            Point3D {
                x: parts[0],
                y: parts[1],
                z: parts[2],
            }
        })
        .collect()
}

fn main() {
    let points = load_input("input.txt");

    println!("--- Part 1 ---");
    let part1 = solve(&points, 1000);
    println!("Answer: {}", part1);

    println!("\n--- Part 2 ---");
    let part2 = solve_part2(&points);
    println!("Answer: {}", part2);
}
