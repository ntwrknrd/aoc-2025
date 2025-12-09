// Advent of Code 2025 - Day 7: Laboratories (tachyon beam simulation)
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// simulateBeams counts how many times beams are split (Part 1)
// Beams at the same position merge - we only care about unique positions
func simulateBeams(grid []string) int {
	// find where the beam enters (the 'S')
	startCol := strings.Index(grid[0], "S")

	// Go doesn't have a built-in set type, so we use map[int]struct{}
	// struct{} takes zero bytes - it's the idiomatic "set" pattern
	beams := map[int]struct{}{startCol: {}}
	totalSplits := 0

	// simulate each row from top to bottom
	for row := 1; row < len(grid); row++ {
		line := grid[row]
		newBeams := make(map[int]struct{})

		for col := range beams {
			// check if this beam hits a splitter
			if col < len(line) && line[col] == '^' {
				// beam hit a splitter! count it and spawn left/right
				totalSplits++
				if col-1 >= 0 {
					newBeams[col-1] = struct{}{}
				}
				if col+1 < len(line) {
					newBeams[col+1] = struct{}{}
				}
			} else {
				// empty space or out of bounds - beam continues down
				if col >= 0 && col < len(line) {
					newBeams[col] = struct{}{}
				}
			}
		}

		beams = newBeams

		// if no beams left, we're done early
		if len(beams) == 0 {
			break
		}
	}

	return totalSplits
}

// countTimelines counts total timelines using many-worlds interpretation (Part 2)
// Particles at the same position are STILL distinct - they don't merge
func countTimelines(grid []string) int64 {
	startCol := strings.Index(grid[0], "S")

	// now we track particle COUNTS at each position
	// map[column]count - multiple particles can stack at same column
	particles := map[int]int64{startCol: 1}

	for row := 1; row < len(grid); row++ {
		line := grid[row]
		newParticles := make(map[int]int64)

		for col, count := range particles {
			if col < len(line) && line[col] == '^' {
				// particle splits into two timelines (left and right)
				// each timeline inherits all the counts from this position
				if col-1 >= 0 {
					newParticles[col-1] += count
				}
				if col+1 < len(line) {
					newParticles[col+1] += count
				}
			} else {
				// continues down - preserves all timeline counts
				if col >= 0 && col < len(line) {
					newParticles[col] += count
				}
			}
		}

		particles = newParticles
		if len(particles) == 0 {
			break
		}
	}

	// total timelines = sum of all particle counts at final positions
	var total int64 = 0
	for _, count := range particles {
		total += count
	}
	return total
}

func loadInput(filename string) []string {
	file, _ := os.Open(filename)
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	// trim trailing empty lines
	for len(lines) > 0 && strings.TrimSpace(lines[len(lines)-1]) == "" {
		lines = lines[:len(lines)-1]
	}

	return lines
}

func main() {
	// example from puzzle description
	example := []string{
		".......S.......",
		"...............",
		".......^.......",
		"...............",
		"......^.^......",
		"...............",
		".....^.^.^.....",
		"...............",
		"....^.^...^....",
		"...............",
		"...^.^...^.^...",
		"...............",
		"..^...^.....^..",
		"...............",
		".^.^.^.^.^...^.",
		"...............",
	}

	fmt.Println("--- Part 1 ---")
	fmt.Printf("Example: %d (expected 21)\n", simulateBeams(example))

	input := loadInput("day07/input.txt")
	fmt.Printf("Answer:  %d\n", simulateBeams(input))

	fmt.Println("\n--- Part 2 ---")
	fmt.Printf("Example: %d (expected 40)\n", countTimelines(example))
	fmt.Printf("Answer:  %d\n", countTimelines(input))
}
