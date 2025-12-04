// Advent of Code 2025 - Day 2: Gift Shop

use std::fs;

// is_double checks if a number is made of a digit sequence repeated twice (like 6464)
fn is_double(n: i64) -> bool {
    let s = format!("{}", n);
    if s.len() % 2 != 0 {
        // odd length can't be a double
        return false;
    }
    let half = s.len() / 2;
    s[..half] == s[half..]
}

// is_repeating checks if a number is a pattern repeated 2+ times (111, 1212, etc)
fn is_repeating(n: i64) -> bool {
    let s = format!("{}", n);
    // try each possible pattern length that divides evenly
    for pattern_len in 1..=s.len() / 2 {
        if s.len() % pattern_len == 0 {
            let pattern = &s[..pattern_len];
            if pattern.repeat(s.len() / pattern_len) == s {
                return true;
            }
        }
    }
    false
}

// generate_doubles_in_range finds all double numbers by checking each candidate
fn generate_doubles_in_range(start: i64, end: i64) -> Vec<i64> {
    (start..=end).filter(|&n| is_double(n)).collect()
}

// generate_repeating_in_range finds all repeating-pattern numbers by checking each candidate
fn generate_repeating_in_range(start: i64, end: i64) -> Vec<i64> {
    (start..=end).filter(|&n| is_repeating(n)).collect()
}

// parse_input splits "11-22,95-115" into vec of (start, end) pairs
fn parse_input(line: &str) -> Vec<(i64, i64)> {
    line.trim()
        .split(',')
        .map(|part| {
            let nums: Vec<&str> = part.split('-').collect();
            let start: i64 = nums[0].parse().unwrap();
            let end: i64 = nums[1].parse().unwrap();
            (start, end)
        })
        .collect()
}

// solve sums all IDs found by finder_fn across all ranges
fn solve<F>(input_line: &str, finder_fn: F) -> i64
where
    F: Fn(i64, i64) -> Vec<i64>,
{
    let ranges = parse_input(input_line);
    ranges
        .iter()
        .map(|(start, end)| finder_fn(*start, *end).iter().sum::<i64>())
        .sum()
}

fn main() {
    let example_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    let real_input = fs::read_to_string("input.txt").unwrap();
    let real_input = real_input.trim();

    // Part 1: doubles like 6464
    println!("--- Part 1 ---");
    let result = solve(example_input, generate_doubles_in_range);
    println!("Example: {}", result); // should be 1227775554
    let answer = solve(real_input, generate_doubles_in_range);
    println!("Answer:  {}", answer);

    // Part 2: any repeating pattern like 111, 1212, 824824824
    println!("\n--- Part 2 ---");
    let result2 = solve(example_input, generate_repeating_in_range);
    println!("Example: {}", result2); // should be 4174379265
    let answer2 = solve(real_input, generate_repeating_in_range);
    println!("Answer:  {}", answer2);
}
