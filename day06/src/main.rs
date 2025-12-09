// Advent of Code 2025 - Day 6: Trash Compactor (cephalopod math worksheet)

use std::fs;

// a problem is a list of numbers and an operator
// Rust tuples work well here - (Vec<i64>, char)

// pad all lines to the same width for column-based access
fn pad_lines(lines: &[&str]) -> (Vec<String>, usize) {
    let max_len = lines.iter().map(|s| s.len()).max().unwrap_or(0);

    let padded: Vec<String> = lines
        .iter()
        .map(|s| format!("{:width$}", s, width = max_len))
        .collect();

    (padded, max_len)
}

// find problem boundaries by looking for columns that are all spaces
fn find_problem_boundaries(lines: &[&str]) -> Vec<(usize, usize)> {
    let (padded, width) = pad_lines(lines);

    let mut boundaries = Vec::new();
    let mut start: Option<usize> = None;

    for col in 0..width {
        // check if this column is all spaces
        // .as_bytes()[col] gives us direct byte access (faster than .chars().nth())
        let all_spaces = padded.iter().all(|line| line.as_bytes()[col] == b' ');

        match (all_spaces, start) {
            (false, None) => start = Some(col), // found start of problem
            (true, Some(s)) => {
                // found end of problem
                boundaries.push((s, col));
                start = None;
            }
            _ => {}
        }
    }

    // don't forget the last problem
    if let Some(s) = start {
        boundaries.push((s, width));
    }

    boundaries
}

// parse worksheet Part 1 style: numbers from each row
fn parse_worksheet(lines: &[&str]) -> Vec<(Vec<i64>, char)> {
    let (padded, _) = pad_lines(lines);
    let bounds = find_problem_boundaries(lines);

    // last row is operators, rest are numbers
    let operator_row = &padded[padded.len() - 1];
    let number_rows = &padded[..padded.len() - 1];

    bounds
        .iter()
        .map(|&(start, end)| {
            // grab number from each row's slice
            let numbers: Vec<i64> = number_rows
                .iter()
                .filter_map(|row| {
                    let chunk = row[start..end].trim();
                    if chunk.is_empty() {
                        None
                    } else {
                        Some(chunk.parse().unwrap())
                    }
                })
                .collect();

            // find operator in this range
            let op_chunk = operator_row[start..end].trim();
            let op = op_chunk.chars().next().unwrap_or('+');

            (numbers, op)
        })
        .collect()
}

// parse worksheet cephalopod style (Part 2): digits in columns, right-to-left
fn parse_worksheet_cephalopod(lines: &[&str]) -> Vec<(Vec<i64>, char)> {
    let (padded, _) = pad_lines(lines);
    let bounds = find_problem_boundaries(lines);

    let operator_row = &padded[padded.len() - 1];
    let number_rows = &padded[..padded.len() - 1];

    bounds
        .iter()
        .map(|&(start, end)| {
            let mut numbers: Vec<i64> = Vec::new();

            // iterate columns right-to-left
            for col in (start..end).rev() {
                // collect digits top-to-bottom
                let digits: String = number_rows
                    .iter()
                    .filter_map(|row| {
                        let ch = row.as_bytes()[col] as char;
                        if ch.is_ascii_digit() {
                            Some(ch)
                        } else {
                            None
                        }
                    })
                    .collect();

                if !digits.is_empty() {
                    numbers.push(digits.parse().unwrap());
                }
            }

            let op_chunk = operator_row[start..end].trim();
            let op = op_chunk.chars().next().unwrap_or('+');

            (numbers, op)
        })
        .collect()
}

// solve by applying operator to each problem and summing results
fn solve(problems: &[(Vec<i64>, char)]) -> i64 {
    problems
        .iter()
        .map(|(numbers, op)| {
            if *op == '+' {
                // turbofish ::<i64> tells Rust what type sum() returns
                numbers.iter().copied().sum::<i64>()
            } else {
                numbers.iter().copied().product::<i64>()
            }
        })
        .sum()
}

fn load_input(filename: &str) -> Vec<String> {
    let content = fs::read_to_string(filename).unwrap();

    // keep lines as-is (don't trim trailing spaces yet!)
    let mut lines: Vec<String> = content.lines().map(|s| s.to_string()).collect();

    // remove trailing empty lines
    while lines.last().map(|s| s.trim().is_empty()).unwrap_or(false) {
        lines.pop();
    }

    lines
}

fn main() {
    // test with example
    let example: Vec<&str> = vec![
        "123 328  51 64 ",
        " 45 64  387 23 ",
        "  6 98  215 314",
        "*   +   *   +  ",
    ];

    println!("--- Part 1 ---");
    let ex_problems = parse_worksheet(&example);
    println!("Example: {} (expected 4277556)", solve(&ex_problems));

    let input = load_input("input.txt");
    let input_refs: Vec<&str> = input.iter().map(|s| s.as_str()).collect();
    let problems = parse_worksheet(&input_refs);
    println!("Answer:  {}", solve(&problems));

    println!("\n--- Part 2 ---");
    let ex_problems2 = parse_worksheet_cephalopod(&example);
    println!("Example: {} (expected 3263827)", solve(&ex_problems2));

    let problems2 = parse_worksheet_cephalopod(&input_refs);
    println!("Answer:  {}", solve(&problems2));
}
