// Advent of Code 2025 - Day 5: Cafeteria ingredient freshness

use std::fs;

// check if an ingredient ID falls within any of the ranges
fn in_range(id: i64, ranges: &[(i64, i64)]) -> bool {
    // .iter().any() is like Python's any() with a generator
    ranges.iter().any(|(start, end)| id >= *start && id <= *end)
}

// merge overlapping/adjacent ranges into minimal set
fn merge_ranges(ranges: &mut Vec<(i64, i64)>) -> Vec<(i64, i64)> {
    if ranges.is_empty() {
        return Vec::new();
    }

    // sort by start value - sort_by_key takes a closure that returns the sort key
    ranges.sort_by_key(|(start, _)| *start);

    let mut merged: Vec<(i64, i64)> = vec![ranges[0]];

    for &(start, end) in &ranges[1..] {
        let last = merged.last_mut().unwrap(); // get mutable ref to last element

        // if this range overlaps or touches the previous one, extend it
        if start <= last.1 + 1 {
            last.1 = last.1.max(end); // .max() is a method on numbers in Rust
        } else {
            // no overlap, start a new merged range
            merged.push((start, end));
        }
    }

    merged
}

// parse the input file into ranges and ingredient IDs
fn load_input(filename: &str) -> (Vec<(i64, i64)>, Vec<i64>) {
    let content = fs::read_to_string(filename).unwrap();

    // split on double newline to get the two sections
    let sections: Vec<&str> = content.split("\n\n").collect();

    // parse ranges - each line is "start-end"
    let ranges: Vec<(i64, i64)> = sections[0]
        .lines()
        .map(|line| {
            let parts: Vec<&str> = line.split('-').collect();
            let start: i64 = parts[0].parse().unwrap();
            let end: i64 = parts[1].parse().unwrap();
            (start, end)
        })
        .collect();

    // parse ingredient IDs
    let ingredients: Vec<i64> = sections[1]
        .lines()
        .filter(|line| !line.is_empty())
        .map(|line| line.parse().unwrap())
        .collect();

    (ranges, ingredients)
}

fn main() {
    let (mut ranges, ingredients) = load_input("input.txt");

    // Part 1: count fresh ingredients (those in ANY range)
    let part1 = ingredients
        .iter()
        .filter(|&&id| in_range(id, &ranges))
        .count();
    println!("Part 1: {}", part1);

    // Part 2: count ALL unique IDs covered by merged ranges
    let merged = merge_ranges(&mut ranges);

    let part2: i64 = merged.iter().map(|(start, end)| end - start + 1).sum();
    println!("Part 2: {}", part2);
}
