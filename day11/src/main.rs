// Advent of Code 2025 - Day 11: Reactor (counting paths through a device network)
//
// Part 1: Count all paths from "you" to "out" in a DAG
// Part 2: Count paths from "svr" to "out" that pass through both "dac" and "fft"

use std::collections::HashMap;
use std::fs;

type Graph = HashMap<String, Vec<String>>;

// cache key is (start, end) - Rust tuples are hashable if their contents are
type Cache = HashMap<(String, String), i64>;

fn parse_input(content: &str) -> Graph {
    let mut graph = HashMap::new();

    for line in content.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        // format: "device: output1 output2 output3"
        let parts: Vec<&str> = line.splitn(2, ": ").collect();
        let device = parts[0].to_string();
        let outputs = if parts.len() > 1 {
            parts[1].split_whitespace().map(String::from).collect()
        } else {
            vec![]
        };

        graph.insert(device, outputs);
    }

    graph
}

// count_paths returns the number of paths from start to end.
// uses memoization since the same subproblems come up repeatedly in DAG traversal.
fn count_paths(graph: &Graph, cache: &mut Cache, start: &str, end: &str) -> i64 {
    // check cache first
    let key = (start.to_string(), end.to_string());
    if let Some(&count) = cache.get(&key) {
        return count;
    }

    // base case: we've reached our destination
    let result = if start == end {
        1
    } else if let Some(outputs) = graph.get(start) {
        // sum paths through all outputs
        outputs.iter().map(|next| count_paths(graph, cache, next, end)).sum()
    } else {
        // dead end: node doesn't exist or has no outputs
        0
    };

    cache.insert(key, result);
    result
}

// count paths from start to end that visit both waypoints.
// multiplication principle: paths(A->B->C) = paths(A->B) * paths(B->C)
// in a DAG, either wp1 comes before wp2 or vice versa - one term will be zero.
fn count_paths_through_both(
    graph: &Graph,
    cache: &mut Cache,
    start: &str,
    end: &str,
    wp1: &str,
    wp2: &str,
) -> i64 {
    // paths hitting wp1 first, then wp2
    let via_wp1_first = count_paths(graph, cache, start, wp1)
        * count_paths(graph, cache, wp1, wp2)
        * count_paths(graph, cache, wp2, end);

    // paths hitting wp2 first, then wp1
    let via_wp2_first = count_paths(graph, cache, start, wp2)
        * count_paths(graph, cache, wp2, wp1)
        * count_paths(graph, cache, wp1, end);

    via_wp1_first + via_wp2_first
}

fn main() {
    let content = fs::read_to_string("input.txt").expect("couldn't read input.txt");
    let graph = parse_input(&content);

    // single cache shared across all queries
    let mut cache = Cache::new();

    println!("--- Part 1 ---");
    let part1 = count_paths(&graph, &mut cache, "you", "out");
    println!("Answer: {}", part1);

    println!("--- Part 2 ---");
    let part2 = count_paths_through_both(&graph, &mut cache, "svr", "out", "dac", "fft");
    println!("Answer: {}", part2);
}
