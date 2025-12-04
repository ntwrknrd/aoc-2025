// Advent of Code 2025 - Day 4: Printing Department
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// countNeighbors counts how many @ symbols are adjacent (8 directions)
func countNeighbors(grid [][]byte, row, col int) int {
	rows := len(grid)
	cols := len(grid[0])
	count := 0

	// check all 8 directions - same nested loop trick as Python
	for dr := -1; dr <= 1; dr++ {
		for dc := -1; dc <= 1; dc++ {
			if dr == 0 && dc == 0 {
				continue // skip the cell itself
			}

			nr, nc := row+dr, col+dc

			// bounds check
			if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
				if grid[nr][nc] == '@' {
					count++
				}
			}
		}
	}

	return count
}

// position is a simple struct to hold row,col - Go doesn't have tuples
type position struct {
	row, col int
}

// findAccessible returns all positions of rolls with < 4 neighbors
func findAccessible(grid [][]byte) []position {
	var accessible []position

	for row := 0; row < len(grid); row++ {
		for col := 0; col < len(grid[0]); col++ {
			if grid[row][col] == '@' {
				neighbors := countNeighbors(grid, row, col)
				if neighbors < 4 {
					accessible = append(accessible, position{row, col})
				}
			}
		}
	}

	return accessible
}

// copyGrid creates a mutable copy of the grid
// [][]byte is a 2D slice - each row is a separate slice
func copyGrid(lines []string) [][]byte {
	grid := make([][]byte, len(lines))
	for i, line := range lines {
		// []byte(line) converts string to byte slice (mutable)
		grid[i] = []byte(line)
	}
	return grid
}

// solve counts rolls accessible by forklift
func solve(lines []string) int {
	grid := copyGrid(lines)
	return len(findAccessible(grid))
}

// solvePart2 keeps removing accessible rolls until none left
func solvePart2(lines []string) int {
	grid := copyGrid(lines)
	totalRemoved := 0

	for {
		accessible := findAccessible(grid)
		if len(accessible) == 0 {
			break // no more to remove
		}

		// remove all accessible rolls
		for _, pos := range accessible {
			grid[pos.row][pos.col] = '.'
		}

		totalRemoved += len(accessible)
	}

	return totalRemoved
}

// loadInput reads non-empty lines from a file
func loadInput(filename string) []string {
	file, _ := os.Open(filename)
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line != "" {
			lines = append(lines, line)
		}
	}
	return lines
}

func main() {
	exampleInput := []string{
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
	}

	// Part 1
	fmt.Println("--- Part 1 ---")
	result := solve(exampleInput)
	fmt.Printf("Example: %d\n", result) // should be 13

	realInput := loadInput("input.txt")
	answer := solve(realInput)
	fmt.Printf("Answer:  %d\n", answer)

	// Part 2
	fmt.Println("\n--- Part 2 ---")
	result2 := solvePart2(exampleInput)
	fmt.Printf("Example: %d\n", result2) // should be 43

	answer2 := solvePart2(realInput)
	fmt.Printf("Answer:  %d\n", answer2)
}
