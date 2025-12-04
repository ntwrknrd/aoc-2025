// Advent of Code 2025 - Day 1: Secret Entrance
package main

// every Go file needs a package declaration at the top
// "main" is special - it means this file can be run directly

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

// parseRotation splits "L68" into direction and distance
// Go functions can return multiple values - this is how we do "tuples"
func parseRotation(rotation string) (string, int) {
	// grab the direction (L or R) - in Go, string[0] gives a byte, not a string
	// so we slice [0:1] to get a string, or just use string(rotation[0])
	direction := string(rotation[0])

	// everything after the first char - strconv.Atoi is like Python's int()
	// it returns (value, error) - we ignore the error with _ for now
	distance, _ := strconv.Atoi(rotation[1:])

	return direction, distance
}

// applyRotation moves the dial and returns new position
func applyRotation(position int, direction string, distance int) int {
	var newPosition int

	if direction == "L" {
		newPosition = position - distance
	} else {
		newPosition = position + distance
	}

	// GOTCHA: Go's % can return negative numbers! -50 % 100 = -50 in Go, but 50 in Python
	// we need to handle this manually
	newPosition = ((newPosition % 100) + 100) % 100
	return newPosition
}

// solve counts how many times the dial lands on 0 after a rotation
func solve(rotations []string) int {
	position := 50 // dial starts at 50
	zeroCount := 0

	// range gives us index and value - we only need value here
	// the _ ignores the index (like Python's "for rotation in rotations")
	for _, rotation := range rotations {
		direction, distance := parseRotation(rotation)
		position = applyRotation(position, direction, distance)
		if position == 0 {
			zeroCount++
		}
	}

	return zeroCount
}

// countZerosCrossed counts how many times we pass through 0 during a rotation
// uses the "count multiples of 100 in range" trick
func countZerosCrossed(start int, direction string, distance int) int {
	var a, b int

	if direction == "L" {
		// going left: hit start-1, start-2, ... down to start-distance
		a = start - distance
		b = start - 1
	} else {
		// going right: hit start+1, start+2, ... up to start+distance
		a = start + 1
		b = start + distance
	}

	// count multiples of 100 in [a, b]
	// Go integer division truncates toward zero, which works for positive numbers
	// but we need floor division for negative numbers
	return floorDiv(b, 100) - floorDiv(a-1, 100)
}

// floorDiv does floor division (like Python's //)
// Go's / truncates toward zero, Python's // floors toward negative infinity
func floorDiv(a, b int) int {
	result := a / b
	// if signs differ and there's a remainder, subtract 1
	if (a < 0) != (b < 0) && a%b != 0 {
		result--
	}
	return result
}

// solvePart2 counts ALL times the dial points at 0
func solvePart2(rotations []string) int {
	position := 50
	zeroCount := 0

	for _, rotation := range rotations {
		direction, distance := parseRotation(rotation)
		zeroCount += countZerosCrossed(position, direction, distance)
		position = applyRotation(position, direction, distance)
	}

	return zeroCount
}

// loadInput reads lines from a file
func loadInput(filename string) []string {
	// os.Open returns (file, error) - again ignoring error for brevity
	file, _ := os.Open(filename)
	defer file.Close() // defer runs this when the function exits - like Python's "with"

	var lines []string
	scanner := bufio.NewScanner(file)

	// scanner.Scan() returns true while there are more lines
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	return lines
}

func main() {
	// example from the puzzle
	exampleInput := []string{"L68", "L30", "R48", "L5", "R60", "L55", "L1", "L99", "R14", "L82"}

	// Part 1
	fmt.Println("--- Part 1 ---")
	result := solve(exampleInput)
	fmt.Printf("Example: %d\n", result) // should be 3

	realInput := loadInput("input.txt")
	answer := solve(realInput)
	fmt.Printf("Answer:  %d\n", answer)

	// Part 2
	fmt.Println("\n--- Part 2 ---")
	result2 := solvePart2(exampleInput)
	fmt.Printf("Example: %d\n", result2) // should be 6

	answer2 := solvePart2(realInput)
	fmt.Printf("Answer:  %d\n", answer2)
}
