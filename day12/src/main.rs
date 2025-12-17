// Advent of Code 2025 - Day 12: Christmas Tree Farm (polyomino packing)
//
// Part 1: Count how many regions can fit all their required shapes

use std::collections::{BTreeSet, HashSet};
use std::fs;

// BTreeSet is used instead of HashSet because it's ordered and implements Hash,
// letting us store shapes in a HashSet for deduplication. HashSet itself isn't hashable.
type Shape = BTreeSet<(i32, i32)>;

struct Region {
    width: usize,
    height: usize,
    counts: Vec<usize>,
}

// normalize shifts a shape so its top-left corner is at (0, 0)
fn normalize(shape: &Shape) -> Shape {
    if shape.is_empty() {
        return shape.clone();
    }

    let min_row = shape.iter().map(|(r, _)| *r).min().unwrap();
    let min_col = shape.iter().map(|(_, c)| *c).min().unwrap();

    shape
        .iter()
        .map(|(r, c)| (r - min_row, c - min_col))
        .collect()
}

// rotate 90 degrees clockwise: (r, c) -> (c, -r)
fn rotate90(shape: &Shape) -> Shape {
    let rotated: Shape = shape.iter().map(|(r, c)| (*c, -r)).collect();
    normalize(&rotated)
}

// flip horizontally: (r, c) -> (r, -c)
fn flip_horizontal(shape: &Shape) -> Shape {
    let flipped: Shape = shape.iter().map(|(r, c)| (*r, -c)).collect();
    normalize(&flipped)
}

// get all unique orientations of a shape (up to 8)
fn get_all_orientations(shape: &Shape) -> Vec<Shape> {
    let mut seen: HashSet<Shape> = HashSet::new();
    let mut orientations = Vec::new();
    let mut current = shape.clone();

    for _ in 0..4 {
        // try both normal and flipped versions
        for s in [&current, &flip_horizontal(&current)] {
            let normalized = normalize(s);
            if seen.insert(normalized.clone()) {
                orientations.push(normalized);
            }
        }
        current = rotate90(&current);
    }

    orientations
}

// parse a shape from lines like "###", "##.", ".##"
fn parse_shape(lines: &[&str]) -> Shape {
    let mut shape = Shape::new();
    for (row, line) in lines.iter().enumerate() {
        for (col, ch) in line.chars().enumerate() {
            if ch == '#' {
                shape.insert((row as i32, col as i32));
            }
        }
    }
    shape
}

fn parse_input(content: &str) -> (Vec<Vec<Shape>>, Vec<Region>) {
    let mut shapes: Vec<Vec<Shape>> = Vec::new();
    let mut regions: Vec<Region> = Vec::new();

    // split into sections by double newline
    let sections: Vec<&str> = content.split("\n\n").collect();

    for section in sections {
        let lines: Vec<&str> = section.lines().collect();
        if lines.is_empty() {
            continue;
        }

        let first_line = lines[0].trim();

        // shape definition: starts with "N:"
        if first_line.ends_with(':') {
            if let Ok(idx) = first_line.trim_end_matches(':').parse::<usize>() {
                let shape_lines: Vec<&str> = lines[1..].iter().map(|s| s.trim()).collect();
                let shape = parse_shape(&shape_lines);

                // ensure shapes vector is big enough
                while shapes.len() <= idx {
                    shapes.push(Vec::new());
                }
                shapes[idx] = get_all_orientations(&shape);
            }
            continue;
        }

        // region definitions: contain "x" in dimensions
        for line in lines {
            if line.contains('x') && line.contains(": ") {
                let parts: Vec<&str> = line.splitn(2, ": ").collect();
                let dims: Vec<&str> = parts[0].split('x').collect();
                let width: usize = dims[0].parse().unwrap();
                let height: usize = dims[1].parse().unwrap();

                let counts: Vec<usize> = parts[1]
                    .split_whitespace()
                    .map(|s| s.parse().unwrap())
                    .collect();

                regions.push(Region {
                    width,
                    height,
                    counts,
                });
            }
        }
    }

    (shapes, regions)
}

// grid tracks which cells are occupied
struct Grid {
    cells: Vec<Vec<bool>>,
    height: usize,
    width: usize,
}

impl Grid {
    fn new(height: usize, width: usize) -> Self {
        Grid {
            cells: vec![vec![false; width]; height],
            height,
            width,
        }
    }

    fn can_place(&self, shape: &Shape, start_row: i32, start_col: i32) -> bool {
        for (dr, dc) in shape {
            let r = start_row + dr;
            let c = start_col + dc;

            if r < 0 || r >= self.height as i32 || c < 0 || c >= self.width as i32 {
                return false;
            }
            if self.cells[r as usize][c as usize] {
                return false;
            }
        }
        true
    }

    fn place(&mut self, shape: &Shape, start_row: i32, start_col: i32, fill: bool) {
        for (dr, dc) in shape {
            let r = (start_row + dr) as usize;
            let c = (start_col + dc) as usize;
            self.cells[r][c] = fill;
        }
    }
}

// backtracking to place all shapes
fn can_place_all(to_place: &[&[Shape]], grid: &mut Grid) -> bool {
    // base case: all shapes placed
    if to_place.is_empty() {
        return true;
    }

    let orientations = to_place[0];
    let remaining = &to_place[1..];

    // try each orientation at each position
    for orientation in orientations {
        for row in 0..grid.height as i32 {
            for col in 0..grid.width as i32 {
                if grid.can_place(orientation, row, col) {
                    grid.place(orientation, row, col, true);

                    if can_place_all(remaining, grid) {
                        return true;
                    }

                    // backtrack
                    grid.place(orientation, row, col, false);
                }
            }
        }
    }

    false
}

fn can_fit_region(shapes: &[Vec<Shape>], region: &Region) -> bool {
    // quick check: do we have enough cells?
    let total_cells: usize = region
        .counts
        .iter()
        .enumerate()
        .filter(|(idx, &count)| count > 0 && *idx < shapes.len() && !shapes[*idx].is_empty())
        .map(|(idx, &count)| count * shapes[idx][0].len())
        .sum();

    if total_cells > region.width * region.height {
        return false;
    }

    // build list of shape orientations to place (one entry per shape instance)
    // using references to avoid cloning
    let mut to_place: Vec<&[Shape]> = Vec::new();
    for (idx, &count) in region.counts.iter().enumerate() {
        if idx < shapes.len() {
            for _ in 0..count {
                to_place.push(&shapes[idx]);
            }
        }
    }

    let mut grid = Grid::new(region.height, region.width);
    can_place_all(&to_place, &mut grid)
}

fn main() {
    let content = fs::read_to_string("input.txt").expect("couldn't read input.txt");
    let (shapes, regions) = parse_input(&content);

    // Part 1: count regions that can fit all their presents
    let count = regions
        .iter()
        .filter(|region| can_fit_region(&shapes, region))
        .count();

    println!("Part 1: {}", count);
}
