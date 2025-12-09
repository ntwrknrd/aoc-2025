// Advent of Code 2025 - Day 6: Trash Compactor (cephalopod math worksheet)
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// problem holds numbers and operator for one math problem
// Go doesn't have tuples, so we use a struct
type problem struct {
	numbers []int64
	op      byte // '+' or '*'
}

// boundary marks start/end columns of a problem in the worksheet
type boundary struct {
	start, end int
}

// padLines ensures all lines are the same width for column-based access
func padLines(lines []string) ([]string, int) {
	maxLen := 0
	for _, line := range lines {
		if len(line) > maxLen {
			maxLen = len(line)
		}
	}

	padded := make([]string, len(lines))
	for i, line := range lines {
		// Go strings are immutable, so we build a new one with padding
		padded[i] = line + strings.Repeat(" ", maxLen-len(line))
	}
	return padded, maxLen
}

// findProblemBoundaries identifies where each problem starts and ends
// by finding columns that are entirely spaces (separators)
func findProblemBoundaries(lines []string) []boundary {
	padded, width := padLines(lines)

	var boundaries []boundary
	start := -1

	for col := 0; col < width; col++ {
		// check if this column is all spaces
		allSpaces := true
		for _, line := range padded {
			// Go lets us index into strings to get bytes
			if line[col] != ' ' {
				allSpaces = false
				break
			}
		}

		if !allSpaces && start == -1 {
			// found start of a new problem
			start = col
		} else if allSpaces && start != -1 {
			// found end of current problem
			boundaries = append(boundaries, boundary{start, col})
			start = -1
		}
	}

	// don't forget the last problem if it runs to the edge
	if start != -1 {
		boundaries = append(boundaries, boundary{start, width})
	}

	return boundaries
}

// parseWorksheet extracts problems from the worksheet (Part 1 style)
// numbers are read row-by-row from each column slice
func parseWorksheet(lines []string) []problem {
	padded, _ := padLines(lines)
	bounds := findProblemBoundaries(lines)

	// last row is operators, rest are numbers
	operatorRow := padded[len(padded)-1]
	numberRows := padded[:len(padded)-1]

	var problems []problem

	for _, b := range bounds {
		var numbers []int64

		// grab the number from each row in this column range
		for _, row := range numberRows {
			chunk := strings.TrimSpace(row[b.start:b.end])
			if chunk != "" {
				num, _ := strconv.ParseInt(chunk, 10, 64)
				numbers = append(numbers, num)
			}
		}

		// find the operator in this column range
		opChunk := strings.TrimSpace(operatorRow[b.start:b.end])
		op := byte('+')
		if len(opChunk) > 0 && (opChunk[0] == '+' || opChunk[0] == '*') {
			op = opChunk[0]
		}

		problems = append(problems, problem{numbers, op})
	}

	return problems
}

// parseWorksheetCephalopod extracts problems cephalopod-style (Part 2)
// digits in each column form a number (top-to-bottom), read right-to-left
func parseWorksheetCephalopod(lines []string) []problem {
	padded, _ := padLines(lines)
	bounds := findProblemBoundaries(lines)

	operatorRow := padded[len(padded)-1]
	numberRows := padded[:len(padded)-1]

	var problems []problem

	for _, b := range bounds {
		var numbers []int64

		// iterate columns right-to-left within this problem
		for col := b.end - 1; col >= b.start; col-- {
			// collect digits from top to bottom
			var digits strings.Builder
			for _, row := range numberRows {
				ch := row[col]
				// Go's isdigit equivalent: check byte range
				if ch >= '0' && ch <= '9' {
					digits.WriteByte(ch)
				}
			}

			if digits.Len() > 0 {
				num, _ := strconv.ParseInt(digits.String(), 10, 64)
				numbers = append(numbers, num)
			}
		}

		opChunk := strings.TrimSpace(operatorRow[b.start:b.end])
		op := byte('+')
		if len(opChunk) > 0 && (opChunk[0] == '+' || opChunk[0] == '*') {
			op = opChunk[0]
		}

		problems = append(problems, problem{numbers, op})
	}

	return problems
}

// solve computes the grand total by solving each problem
func solve(problems []problem) int64 {
	var total int64 = 0

	for _, p := range problems {
		var result int64
		if p.op == '+' {
			result = 0
			for _, n := range p.numbers {
				result += n
			}
		} else {
			result = 1
			for _, n := range p.numbers {
				result *= n
			}
		}
		total += result
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
	// test with example
	example := []string{
		"123 328  51 64 ",
		" 45 64  387 23 ",
		"  6 98  215 314",
		"*   +   *   +  ",
	}

	fmt.Println("--- Part 1 ---")
	exProblems := parseWorksheet(example)
	fmt.Printf("Example: %d (expected 4277556)\n", solve(exProblems))

	input := loadInput("day06/input.txt")
	problems := parseWorksheet(input)
	fmt.Printf("Answer:  %d\n", solve(problems))

	fmt.Println("\n--- Part 2 ---")
	exProblems2 := parseWorksheetCephalopod(example)
	fmt.Printf("Example: %d (expected 3263827)\n", solve(exProblems2))

	problems2 := parseWorksheetCephalopod(input)
	fmt.Printf("Answer:  %d\n", solve(problems2))
}
