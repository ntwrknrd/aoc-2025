// Advent of Code 2025 - Day 4: Printing Department

use std::fs;

// count_neighbors checks how many @ symbols surround a cell (8 directions)
fn count_neighbors(grid: &[Vec<u8>], row: usize, col: usize) -> usize {
    let rows = grid.len();
    let cols = grid[0].len();
    let mut count = 0;

    // we use isize for deltas because we need to subtract
    // usize can't be negative, so we'd panic on 0 - 1
    let deltas: [(isize, isize); 8] = [
        (-1, -1),
        (-1, 0),
        (-1, 1),
        (0, -1),
        (0, 1),
        (1, -1),
        (1, 0),
        (1, 1),
    ];

    for (dr, dc) in deltas {
        // as isize converts usize to signed so we can add negative deltas
        let nr = row as isize + dr;
        let nc = col as isize + dc;

        // bounds check - negative numbers fail the >= 0 check
        if nr >= 0 && nc >= 0 {
            let nr = nr as usize;
            let nc = nc as usize;
            // make sure we're still inside the grid
            if nr < rows && nc < cols && grid[nr][nc] == b'@' {
                count += 1;
            }
        }
    }

    count
}

// find_accessible returns all (row, col) positions with < 4 neighbors
fn find_accessible(grid: &[Vec<u8>]) -> Vec<(usize, usize)> {
    let mut accessible = Vec::new();

    for row in 0..grid.len() {
        for col in 0..grid[0].len() {
            if grid[row][col] == b'@' {
                let neighbors = count_neighbors(grid, row, col);
                if neighbors < 4 {
                    accessible.push((row, col));
                }
            }
        }
    }

    accessible
}

// solve counts rolls accessible by forklift (part 1)
fn solve(grid: &[&str]) -> usize {
    // convert from &[&str] to Vec<Vec<u8>>
    // .bytes().collect() turns each string into a Vec of bytes
    let grid: Vec<Vec<u8>> = grid.iter().map(|s| s.bytes().collect()).collect();
    find_accessible(&grid).len()
}

// solve_part2 keeps removing accessible rolls until none left
fn solve_part2(grid: &[&str]) -> usize {
    // need mutable copy of the grid
    let mut grid: Vec<Vec<u8>> = grid.iter().map(|s| s.bytes().collect()).collect();
    let mut total_removed = 0;

    // Rust doesn't have while True, we use loop {} with break instead
    loop {
        let accessible = find_accessible(&grid);
        if accessible.is_empty() {
            break;
        }

        // remove all accessible rolls by replacing @ with .
        for (row, col) in &accessible {
            grid[*row][*col] = b'.';
        }

        total_removed += accessible.len();
    }

    total_removed
}

fn main() {
    // example from the puzzle
    let example_input = vec![
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    ];

    // Part 1
    println!("--- Part 1 ---");
    let result = solve(&example_input);
    println!("Example: {}", result); // should be 13

    let real_input = fs::read_to_string("input.txt").unwrap();
    let lines: Vec<&str> = real_input.lines().filter(|s| !s.is_empty()).collect();
    let answer = solve(&lines);
    println!("Answer:  {}", answer);

    // Part 2
    println!("\n--- Part 2 ---");
    let result2 = solve_part2(&example_input);
    println!("Example: {}", result2); // should be 43

    let answer2 = solve_part2(&lines);
    println!("Answer:  {}", answer2);
}
