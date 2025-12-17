// Advent of Code 2025 - Day 9: Movie Theater (largest rectangle from tile corners)
//
// O(n) approach: the optimal rectangle always involves "extreme" points.
// We track 8 extremes (4 axis-aligned + 4 diagonal) and check only those pairs.

use std::collections::{BTreeSet, HashSet};
use std::fs;

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
struct Point {
    x: i64,
    y: i64,
}

fn solve(tiles: &[Point]) -> i64 {
    if tiles.len() < 2 {
        return 0;
    }

    // track extreme points in a single pass
    let mut min_x_pt = tiles[0];
    let mut max_x_pt = tiles[0];
    let mut min_y_pt = tiles[0];
    let mut max_y_pt = tiles[0];
    let mut min_sum_pt = tiles[0]; // x+y extremes (diagonal)
    let mut max_sum_pt = tiles[0];
    let mut min_diff_pt = tiles[0]; // x-y extremes (anti-diagonal)
    let mut max_diff_pt = tiles[0];

    for &p in tiles {
        // axis-aligned extremes
        if p.x < min_x_pt.x {
            min_x_pt = p;
        }
        if p.x > max_x_pt.x {
            max_x_pt = p;
        }
        if p.y < min_y_pt.y {
            min_y_pt = p;
        }
        if p.y > max_y_pt.y {
            max_y_pt = p;
        }

        // diagonal extremes
        let sum = p.x + p.y;
        let diff = p.x - p.y;
        if sum < min_sum_pt.x + min_sum_pt.y {
            min_sum_pt = p;
        }
        if sum > max_sum_pt.x + max_sum_pt.y {
            max_sum_pt = p;
        }
        if diff < min_diff_pt.x - min_diff_pt.y {
            min_diff_pt = p;
        }
        if diff > max_diff_pt.x - max_diff_pt.y {
            max_diff_pt = p;
        }
    }

    // collect unique candidates using HashSet
    let candidates: Vec<Point> = [
        min_x_pt,
        max_x_pt,
        min_y_pt,
        max_y_pt,
        min_sum_pt,
        max_sum_pt,
        min_diff_pt,
        max_diff_pt,
    ]
    .iter()
    .copied()
    .collect::<HashSet<_>>()
    .into_iter()
    .collect();

    // check all pairs among candidates (at most 28 pairs)
    let mut max_area: i64 = 0;
    for i in 0..candidates.len() {
        for j in (i + 1)..candidates.len() {
            let p1 = candidates[i];
            let p2 = candidates[j];
            // +1 because tiles are squares - both corners included
            let width = (p2.x - p1.x).abs() + 1;
            let height = (p2.y - p1.y).abs() + 1;
            let area = width * height;
            max_area = max_area.max(area);
        }
    }

    max_area
}

/// Vertical edge from (x, y_lo) to (x, y_hi)
struct VerticalEdge {
    x: i64,
    y_lo: i64,
    y_hi: i64,
}

/// Find largest rectangle with red corners where all tiles are valid (red or green).
/// Uses sparse tables for O(1) range queries on polygon boundaries.
fn solve_part2(tiles: &[Point]) -> i64 {
    if tiles.len() < 2 {
        return 0;
    }

    let n = tiles.len();

    // build vertical edges using iterator over consecutive pairs (wrapping)
    let vertical_edges: Vec<VerticalEdge> = (0..n)
        .map(|i| (&tiles[i], &tiles[(i + 1) % n]))
        .filter(|(p1, p2)| p1.x == p2.x)
        .map(|(p1, p2)| VerticalEdge {
            x: p1.x,
            y_lo: p1.y.min(p2.y),
            y_hi: p1.y.max(p2.y),
        })
        .collect();

    // BTreeSet gives us sorted unique y-values directly
    let all_ys: Vec<i64> = tiles
        .iter()
        .map(|p| p.y)
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect();
    let k = all_ys.len();

    // compute left[y] and right[y] using chained iterators (no intermediate Vec)
    let (left_arr, right_arr): (Vec<i64>, Vec<i64>) = all_ys
        .iter()
        .map(|&y| {
            // chain edge x's with tile x's, fold to find min/max in one pass
            vertical_edges
                .iter()
                .filter(|e| e.y_lo <= y && y <= e.y_hi)
                .map(|e| e.x)
                .chain(tiles.iter().filter(|p| p.y == y).map(|p| p.x))
                .fold((i64::MAX, i64::MIN), |(min, max), x| {
                    (min.min(x), max.max(x))
                })
        })
        .unzip();

    // build flattened sparse tables: [max_left..., min_right...]
    let log_k = if k > 1 { (k.ilog2() + 1) as usize } else { 1 };
    let table_size = log_k * k;
    let mut sparse: Vec<i64> = vec![0; table_size * 2];

    // helper to index: table 0 = max_left, table 1 = min_right
    let idx = |table: usize, level: usize, pos: usize| table * table_size + level * k + pos;

    // initialize level 0
    for i in 0..k {
        sparse[idx(0, 0, i)] = left_arr[i];
        sparse[idx(1, 0, i)] = right_arr[i];
    }

    // build higher levels
    for j in 1..log_k {
        let half = 1 << (j - 1);
        let step = half << 1;
        if step > k {
            continue;
        }

        for i in 0..=(k - step) {
            sparse[idx(0, j, i)] = sparse[idx(0, j - 1, i)].max(sparse[idx(0, j - 1, i + half)]);
            sparse[idx(1, j, i)] = sparse[idx(1, j - 1, i)].min(sparse[idx(1, j - 1, i + half)]);
        }
    }

    // query closures using ilog2
    let query = |table: usize, lo: usize, hi: usize| -> i64 {
        let length = hi - lo + 1;
        let j = length.ilog2() as usize;
        let idx2 = hi + 1 - (1 << j);
        if table == 0 {
            sparse[idx(0, j, lo)].max(sparse[idx(0, j, idx2)])
        } else {
            sparse[idx(1, j, lo)].min(sparse[idx(1, j, idx2)])
        }
    };

    // check all pairs of red tiles
    let mut max_area: i64 = 0;

    for i in 0..n {
        let (x1, y1) = (tiles[i].x, tiles[i].y);
        for j in (i + 1)..n {
            let (x2, y2) = (tiles[j].x, tiles[j].y);

            let (rx_lo, rx_hi) = (x1.min(x2), x1.max(x2));
            let (ry_lo, ry_hi) = (y1.min(y2), y1.max(y2));

            let potential = (rx_hi - rx_lo + 1) * (ry_hi - ry_lo + 1);
            if potential <= max_area {
                continue;
            }

            // binary search for y indices (O(log k))
            let iy_lo = all_ys.binary_search(&ry_lo).unwrap();
            let iy_hi = all_ys.binary_search(&ry_hi).unwrap();

            let ml = query(0, iy_lo, iy_hi);
            let mr = query(1, iy_lo, iy_hi);

            if ml <= rx_lo && mr >= rx_hi {
                max_area = potential;
            }
        }
    }

    max_area
}

fn load_input(filename: &str) -> Vec<Point> {
    let content = fs::read_to_string(filename).expect("couldn't read file");
    content
        .lines()
        .filter(|line| !line.is_empty())
        .map(|line| {
            // parse "x,y" format
            let parts: Vec<i64> = line.split(',').map(|s| s.parse().unwrap()).collect();
            Point {
                x: parts[0],
                y: parts[1],
            }
        })
        .collect()
}

fn main() {
    let tiles = load_input("input.txt");

    println!("--- Part 1 ---");
    let part1 = solve(&tiles);
    println!("Answer: {}", part1);

    println!("--- Part 2 ---");
    let part2 = solve_part2(&tiles);
    println!("Answer: {}", part2);
}
