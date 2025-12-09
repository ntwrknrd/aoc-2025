// Advent of Code 2025 - Day 7: Laboratories (tachyon beam splitter manifold)
//
// Simulate beams traveling down through a grid of splitters (^).
// Part 1: count how many times any beam hits a splitter
// Part 2: count distinct timelines (many-worlds quantum interpretation)

use std::collections::{HashMap, HashSet};
use std::fs;

// Part 1: track unique beam positions, count total splits
fn simulate_beams(grid: &[&str]) -> usize {
    // find where the beam enters (the 'S')
    let start_col = grid[0].find('S').expect("no start position");

    // track active beam positions as a set - handles merging automatically
    // HashSet is Rust's equivalent to Python's set
    let mut beams: HashSet<usize> = HashSet::new();
    beams.insert(start_col);

    let mut total_splits = 0;

    // simulate each row from top to bottom
    // .skip(1) starts at row 1 (skip the S row)
    for line in grid.iter().skip(1).map(|s| s.as_bytes()) {
        let mut new_beams: HashSet<usize> = HashSet::new();

        for &col in &beams {
            // check if this beam hits a splitter
            if col < line.len() && line[col] == b'^' {
                // beam hit a splitter! count it and spawn left/right
                total_splits += 1;

                // checked_sub prevents underflow on usize (can't go negative)
                if let Some(left) = col.checked_sub(1) {
                    new_beams.insert(left);
                }
                if col + 1 < line.len() {
                    new_beams.insert(col + 1);
                }
            } else {
                // empty space - beam continues straight down
                if col < line.len() {
                    new_beams.insert(col);
                }
            }
        }

        beams = new_beams;

        // if no beams left, we're done
        if beams.is_empty() {
            break;
        }
    }

    total_splits
}

// Part 2: count distinct timelines using many-worlds interpretation
fn count_timelines(grid: &[&str]) -> u64 {
    let start_col = grid[0].find('S').expect("no start position");

    // now we track particle COUNTS at each position, not just presence
    // particles at same position are still distinct timelines
    let mut particles: HashMap<usize, u64> = HashMap::new();
    particles.insert(start_col, 1);

    for line in grid.iter().skip(1).map(|s| s.as_bytes()) {
        let mut new_particles: HashMap<usize, u64> = HashMap::new();

        for (&col, &count) in &particles {
            if col < line.len() && line[col] == b'^' {
                // particle splits into two timelines (left and right)
                // .entry().or_insert(0) is like Python's dict.get(key, 0)
                if let Some(left) = col.checked_sub(1) {
                    *new_particles.entry(left).or_insert(0) += count;
                }
                if col + 1 < line.len() {
                    *new_particles.entry(col + 1).or_insert(0) += count;
                }
            } else if col < line.len() {
                // continues down - preserves all timeline counts
                *new_particles.entry(col).or_insert(0) += count;
            }
        }

        particles = new_particles;
        if particles.is_empty() {
            break;
        }
    }

    // total timelines = sum of all particle counts
    particles.values().sum()
}

fn main() {
    let content = fs::read_to_string("input.txt").expect("couldn't read input.txt");
    let grid: Vec<&str> = content.lines().collect();

    println!("--- Part 1 ---");
    let part1 = simulate_beams(&grid);
    println!("Answer: {}", part1);

    println!("\n--- Part 2 ---");
    let part2 = count_timelines(&grid);
    println!("Answer: {}", part2);
}
