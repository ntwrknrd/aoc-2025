// Advent of Code 2025 - Day 2: Gift Shop
package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// isDouble checks if a number is made of a digit sequence repeated twice (like 6464)
func isDouble(n int64) bool {
	s := strconv.FormatInt(n, 10)
	if len(s)%2 != 0 { // odd length can't be a double
		return false
	}
	half := len(s) / 2
	return s[:half] == s[half:]
}

// isRepeating checks if a number is a pattern repeated 2+ times (111, 1212, etc)
func isRepeating(n int64) bool {
	s := strconv.FormatInt(n, 10)
	// try each possible pattern length that divides evenly
	for patternLen := 1; patternLen <= len(s)/2; patternLen++ {
		if len(s)%patternLen == 0 {
			pattern := s[:patternLen]
			if strings.Repeat(pattern, len(s)/patternLen) == s {
				return true
			}
		}
	}
	return false
}

// generateDoublesInRange finds all double numbers in range by checking each candidate
func generateDoublesInRange(start, end int64) []int64 {
	var result []int64
	for n := start; n <= end; n++ {
		if isDouble(n) {
			result = append(result, n)
		}
	}
	return result
}

// generateRepeatingInRange finds all repeating-pattern numbers in range
func generateRepeatingInRange(start, end int64) []int64 {
	var result []int64
	for n := start; n <= end; n++ {
		if isRepeating(n) {
			result = append(result, n)
		}
	}
	return result
}

// parseInput splits "11-22,95-115" into pairs of (start, end)
func parseInput(line string) [][2]int64 {
	// Go doesn't have tuples, so we use [2]int64 (fixed-size array)
	var ranges [][2]int64

	line = strings.TrimSpace(line)

	parts := strings.Split(line, ",")
	for _, part := range parts {
		nums := strings.Split(part, "-")
		start, _ := strconv.ParseInt(nums[0], 10, 64)
		end, _ := strconv.ParseInt(nums[1], 10, 64)
		ranges = append(ranges, [2]int64{start, end})
	}

	return ranges
}

// solve sums all IDs found by finderFn across all ranges
// finderFn is a function that returns matching numbers in a range
func solve(inputLine string, finderFn func(int64, int64) []int64) int64 {
	ranges := parseInput(inputLine)
	var total int64

	for _, r := range ranges {
		start, end := r[0], r[1]
		matches := finderFn(start, end)
		for _, m := range matches {
			total += m
		}
	}

	return total
}

func main() {
	exampleInput := "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124"

	realInputBytes, _ := os.ReadFile("input.txt")
	realInput := strings.TrimSpace(string(realInputBytes))

	// Part 1: doubles like 6464
	fmt.Println("--- Part 1 ---")
	result := solve(exampleInput, generateDoublesInRange)
	fmt.Printf("Example: %d\n", result) // should be 1227775554
	answer := solve(realInput, generateDoublesInRange)
	fmt.Printf("Answer:  %d\n", answer)

	// Part 2: any repeating pattern like 111, 1212, 824824824
	fmt.Println("\n--- Part 2 ---")
	result2 := solve(exampleInput, generateRepeatingInRange)
	fmt.Printf("Example: %d\n", result2) // should be 4174379265
	answer2 := solve(realInput, generateRepeatingInRange)
	fmt.Printf("Answer:  %d\n", answer2)
}
