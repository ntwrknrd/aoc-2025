// Advent of Code 2025 - Day 3: Lobby

use std::fs;

// max_joltage finds the largest 2-digit number from picking two batteries at i < j
fn max_joltage(bank: &str) -> u32 {
    // .as_bytes() gives us &[u8] - raw bytes, not chars
    // This is faster than .chars() when we know we have ASCII digits
    let bytes = bank.as_bytes();
    let n = bytes.len();

    // suffix_max[i] = largest digit from position i to the end
    // vec![0u8; n] creates a Vec of n zeros - like [0] * n in Python
    let mut suffix_max: Vec<u8> = vec![0; n];

    // bytes[n-1] is the last byte - we subtract b'0' to convert '5' -> 5
    // b'0' is the byte value of the ASCII character '0' (which is 48)
    suffix_max[n - 1] = bytes[n - 1] - b'0';

    // build suffix_max backwards: (n-2)..0 stepping by -1
    // Rust ranges don't go backwards, so we use .rev()
    for i in (0..n - 1).rev() {
        let digit = bytes[i] - b'0';
        // std::cmp::max is like Python's max()
        suffix_max[i] = std::cmp::max(digit, suffix_max[i + 1]);
    }

    // try each position as tens digit
    let mut max_val: u32 = 0;
    for i in 0..n - 1 {
        let tens = (bytes[i] - b'0') as u32;
        let units = suffix_max[i + 1] as u32;
        let candidate = tens * 10 + units;
        max_val = std::cmp::max(max_val, candidate);
    }

    max_val
}

// solve sums max 2-digit joltage for each bank
fn solve(lines: &[&str]) -> u32 {
    lines.iter().map(|line| max_joltage(line)).sum()
}

// max_joltage_k finds the largest k-digit number using greedy selection
// This is the fun one - we pick digits left-to-right, always grabbing the
// largest we can while still leaving room for remaining picks
fn max_joltage_k(bank: &str, k: usize) -> u64 {
    let bytes = bank.as_bytes();
    let n = bytes.len();

    // String::with_capacity pre-allocates space - slight optimization
    let mut result = String::with_capacity(k);
    let mut start = 0; // where we can start looking for next digit

    for i in 0..k {
        let remaining = k - i - 1; // digits still needed after this one
        let end = n - remaining; // can't pick past here

        // find the largest digit in [start, end)
        let mut best_pos = start;
        for j in (start + 1)..end {
            // we can compare bytes directly since ASCII digits are ordered
            if bytes[j] > bytes[best_pos] {
                best_pos = j;
            }
        }

        // bytes[best_pos] is a u8, need to convert to char
        // as char coerces the byte to a Unicode code point
        result.push(bytes[best_pos] as char);
        start = best_pos + 1;
    }

    // parse our assembled digits into a u64
    // we use u64 because 12-digit numbers can exceed u32::MAX
    result.parse().unwrap()
}

// solve_part2 sums max 12-digit joltage for each bank
fn solve_part2(lines: &[&str]) -> u64 {
    lines.iter().map(|line| max_joltage_k(line, 12)).sum()
}

fn main() {
    // example from the puzzle
    let example_input = vec![
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111",
    ];

    // Part 1
    println!("--- Part 1 ---");
    let result = solve(&example_input);
    println!("Example: {}", result); // should be 357

    // fs::read_to_string reads the whole file into a String
    let real_input = fs::read_to_string("input.txt").unwrap();
    // collect lines, skipping empty ones - filter() is like Python's filter()
    let lines: Vec<&str> = real_input.lines().filter(|s| !s.is_empty()).collect();
    let answer = solve(&lines);
    println!("Answer:  {}", answer);

    // Part 2
    println!("\n--- Part 2 ---");
    let result2 = solve_part2(&example_input);
    println!("Example: {}", result2); // should be 3121910778619

    let answer2 = solve_part2(&lines);
    println!("Answer:  {}", answer2);
}
