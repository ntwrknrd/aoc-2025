// Advent of Code 2025 - Day 1: Secret Entrance

use std::fs;

// parse_rotation splits "L68" into (direction, distance)
// &str is a "string slice" - a borrowed reference to string data
// Rust strings are UTF-8, so we work with chars, not bytes
fn parse_rotation(rotation: &str) -> (char, i32) {
    // .chars().next() gets the first character
    // .unwrap() panics if None - fine for AoC, but real code would handle errors
    let direction = rotation.chars().next().unwrap();

    // &rotation[1..] slices from index 1 to end (like Python's [1:])
    // .parse() converts string to number, returns Result<T, E>
    // ::<i32> is a "turbofish" - tells Rust what type to parse into
    let distance: i32 = rotation[1..].parse().unwrap();

    (direction, distance)
}

// apply_rotation moves the dial and returns new position
fn apply_rotation(position: i32, direction: char, distance: i32) -> i32 {
    let new_position = if direction == 'L' {
        position - distance
    } else {
        position + distance
    };

    // GOTCHA: Rust's % can be negative! -50 % 100 = -50, not 50 like Python
    // rem_euclid gives us Python-style modulo (always positive)
    new_position.rem_euclid(100)
}

// solve counts how many times the dial lands on 0
fn solve(rotations: &[&str]) -> i32 {
    // &[&str] is a slice of string slices - like a borrowed list of strings
    let mut position = 50; // mut means mutable - Rust vars are immutable by default!
    let mut zero_count = 0;

    for rotation in rotations {
        let (direction, distance) = parse_rotation(rotation);
        position = apply_rotation(position, direction, distance);
        if position == 0 {
            zero_count += 1;
        }
    }

    zero_count
}

// count_zeros_crossed counts zeros we pass through during a rotation
fn count_zeros_crossed(start: i32, direction: char, distance: i32) -> i32 {
    let (a, b) = if direction == 'L' {
        (start - distance, start - 1)
    } else {
        (start + 1, start + distance)
    };

    // count multiples of 100 in [a, b]
    // div_euclid is floor division (like Python's //)
    b.div_euclid(100) - (a - 1).div_euclid(100)
}

// solve_part2 counts ALL times the dial points at 0
fn solve_part2(rotations: &[&str]) -> i32 {
    let mut position = 50;
    let mut zero_count = 0;

    for rotation in rotations {
        let (direction, distance) = parse_rotation(rotation);
        zero_count += count_zeros_crossed(position, direction, distance);
        position = apply_rotation(position, direction, distance);
    }

    zero_count
}

// load_input reads lines from a file
fn load_input(filename: &str) -> Vec<String> {
    // fs::read_to_string reads entire file into a String
    // Vec<String> is like Python's list[str]
    let content = fs::read_to_string(filename).unwrap();

    // .lines() returns an iterator over lines
    // .map(|s| s.to_string()) converts each &str to owned String
    // .collect() gathers iterator results into a Vec
    content.lines().map(|s| s.to_string()).collect()
}

fn main() {
    // example from the puzzle
    // vec! is a macro that creates a Vec (like Python's list)
    let example_input = vec![
        "L68", "L30", "R48", "L5", "R60", "L55", "L1", "L99", "R14", "L82",
    ];

    // Part 1
    println!("--- Part 1 ---");
    let result = solve(&example_input);
    println!("Example: {}", result); // should be 3

    let real_input = load_input("input.txt");
    // we need to convert Vec<String> to Vec<&str> for our solve function
    let real_refs: Vec<&str> = real_input.iter().map(|s| s.as_str()).collect();
    let answer = solve(&real_refs);
    println!("Answer:  {}", answer);

    // Part 2
    println!("\n--- Part 2 ---");
    let result2 = solve_part2(&example_input);
    println!("Example: {}", result2); // should be 6

    let answer2 = solve_part2(&real_refs);
    println!("Answer:  {}", answer2);
}
