// Advent of Code 2025 - Day 9: Movie Theater (largest rectangle from tile corners)
//
// O(n) approach: the optimal rectangle always involves "extreme" points.
// We track 8 extremes (4 axis-aligned + 4 diagonal) and check only those pairs.

use std::collections::HashSet;
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
        min_x_pt, max_x_pt, min_y_pt, max_y_pt,
        min_sum_pt, max_sum_pt, min_diff_pt, max_diff_pt,
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
}
