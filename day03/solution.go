// Advent of Code 2025 - Day 3: Lobby
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// maxJoltage finds the maximum 2-digit number from picking 2 batteries
// we precompute suffix_max to avoid rescanning for the best digit after each position
func maxJoltage(bank string) int {
	n := len(bank)

	// suffixMax[i] = largest digit from position i to the end
	// make() creates a slice - like Python's [0] * n
	suffixMax := make([]int, n)

	// bank[n-1] is a byte (uint8), we convert to int by subtracting '0'
	// in Go, '0' is the byte value 48, '9' is 57, so '5' - '0' = 5
	suffixMax[n-1] = int(bank[n-1] - '0')

	// build backwards
	for i := n - 2; i >= 0; i-- {
		digit := int(bank[i] - '0')
		if digit > suffixMax[i+1] {
			suffixMax[i] = digit
		} else {
			suffixMax[i] = suffixMax[i+1]
		}
	}

	// try each position as tens digit, pair with best units digit after it
	maxVal := 0
	for i := 0; i < n-1; i++ {
		tens := int(bank[i] - '0')
		units := suffixMax[i+1]
		candidate := tens*10 + units
		if candidate > maxVal {
			maxVal = candidate
		}
	}

	return maxVal
}

// solve sums the max 2-digit joltage from each bank
func solve(lines []string) int {
	total := 0
	for _, line := range lines {
		total += maxJoltage(line)
	}
	return total
}

// maxJoltageK finds the maximum k-digit number by picking k batteries
// greedy: pick left to right, always grab the largest digit we can
func maxJoltageK(bank string, k int) int64 {
	n := len(bank)
	var result strings.Builder // like Python's joining a list, but more efficient

	start := 0 // where we can start looking

	for i := 0; i < k; i++ {
		remaining := k - i - 1 // digits still needed after this one
		end := n - remaining   // can't pick past here

		// find largest digit in [start, end)
		bestPos := start
		for j := start + 1; j < end; j++ {
			if bank[j] > bank[bestPos] {
				bestPos = j
			}
		}

		result.WriteByte(bank[bestPos]) // append the character
		start = bestPos + 1             // next pick must come after
	}

	// parse the built string to int64
	num, _ := strconv.ParseInt(result.String(), 10, 64)
	return num
}

// solvePart2 sums the max 12-digit joltage from each bank
func solvePart2(lines []string) int64 {
	var total int64
	for _, line := range lines {
		total += maxJoltageK(line, 12)
	}
	return total
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
		"987654321111111",
		"811111111111119",
		"234234234234278",
		"818181911112111",
	}

	// Part 1
	fmt.Println("--- Part 1 ---")
	result := solve(exampleInput)
	fmt.Printf("Example: %d\n", result) // should be 357

	realInput := loadInput("input.txt")
	answer := solve(realInput)
	fmt.Printf("Answer:  %d\n", answer)

	// Part 2
	fmt.Println("\n--- Part 2 ---")
	result2 := solvePart2(exampleInput)
	fmt.Printf("Example: %d\n", result2) // should be 3121910778619

	answer2 := solvePart2(realInput)
	fmt.Printf("Answer:  %d\n", answer2)
}
