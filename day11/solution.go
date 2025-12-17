// Advent of Code 2025 - Day 11: Reactor (counting paths through a device network)
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// PathCounter holds the graph and a cache for memoized path counting.
// In Go we don't have decorators like Python's @cache, so we manage it manually.
type PathCounter struct {
	graph map[string][]string
	cache map[cacheKey]int
}

// cacheKey lets us use (start, end) pairs as map keys
type cacheKey struct {
	start, end string
}

func NewPathCounter(graph map[string][]string) *PathCounter {
	return &PathCounter{
		graph: graph,
		cache: make(map[cacheKey]int),
	}
}

// CountPaths returns the number of paths from start to end in the DAG.
// Results are memoized since the same subproblems come up repeatedly.
func (pc *PathCounter) CountPaths(start, end string) int {
	// check cache first
	key := cacheKey{start, end}
	if count, ok := pc.cache[key]; ok {
		return count
	}

	// base case: reached destination
	if start == end {
		pc.cache[key] = 1
		return 1
	}

	// dead end: node doesn't exist or has no outputs
	outputs, exists := pc.graph[start]
	if !exists {
		pc.cache[key] = 0
		return 0
	}

	// sum paths through all outputs
	total := 0
	for _, neighbor := range outputs {
		total += pc.CountPaths(neighbor, end)
	}

	pc.cache[key] = total
	return total
}

// CountPathsThroughBoth counts paths from start to end that visit both waypoints.
// Uses the multiplication principle: paths(A->B->C) = paths(A->B) * paths(B->C)
// In a DAG, either wp1 comes before wp2 or vice versa (not both), so one term is zero.
func (pc *PathCounter) CountPathsThroughBoth(start, end, wp1, wp2 string) int {
	// paths hitting wp1 first, then wp2
	viaWp1First := pc.CountPaths(start, wp1) *
		pc.CountPaths(wp1, wp2) *
		pc.CountPaths(wp2, end)

	// paths hitting wp2 first, then wp1
	viaWp2First := pc.CountPaths(start, wp2) *
		pc.CountPaths(wp2, wp1) *
		pc.CountPaths(wp1, end)

	return viaWp1First + viaWp2First
}

func parseInput(filename string) (map[string][]string, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	graph := make(map[string][]string)
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// format: "device: output1 output2 output3"
		parts := strings.SplitN(line, ": ", 2)
		device := parts[0]

		var outputs []string
		if len(parts) > 1 && parts[1] != "" {
			outputs = strings.Fields(parts[1])
		}
		graph[device] = outputs
	}

	return graph, scanner.Err()
}

func main() {
	graph, err := parseInput("day11/input.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	pc := NewPathCounter(graph)

	fmt.Println("--- Part 1 ---")
	part1 := pc.CountPaths("you", "out")
	fmt.Printf("Answer: %d\n", part1)

	fmt.Println("--- Part 2 ---")
	part2 := pc.CountPathsThroughBoth("svr", "out", "dac", "fft")
	fmt.Printf("Answer: %d\n", part2)
}
