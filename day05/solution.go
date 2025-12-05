// Advent of Code 2025 - Day 5: Cafeteria ingredient freshness
package main

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
)

// idRange represents a start-end range - Go doesn't have tuples like Python
type idRange struct {
	start, end int64
}

// inRange checks if an ingredient ID falls within any of the ranges
func inRange(id int64, ranges []idRange) bool {
	for _, r := range ranges {
		if id >= r.start && id <= r.end {
			return true
		}
	}
	return false
}

// mergeRanges combines overlapping/adjacent ranges into minimal set
func mergeRanges(ranges []idRange) []idRange {
	if len(ranges) == 0 {
		return ranges
	}

	// sort by start value - sort.Slice takes a "less" function
	// this is like Python's key=lambda but more explicit
	sort.Slice(ranges, func(i, j int) bool {
		return ranges[i].start < ranges[j].start
	})

	merged := []idRange{ranges[0]}

	for _, r := range ranges[1:] {
		last := &merged[len(merged)-1] // pointer so we can modify it

		// if this range overlaps or touches the previous one, extend it
		if r.start <= last.end+1 {
			// max() wasn't built-in until Go 1.21, but we have it now
			last.end = max(last.end, r.end)
		} else {
			// no overlap, start a new merged range
			merged = append(merged, r)
		}
	}

	return merged
}

// loadInput parses the two-section input file
func loadInput(filename string) ([]idRange, []int64) {
	file, _ := os.Open(filename)
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	// find the blank line that separates sections
	splitIdx := 0
	for i, line := range lines {
		if strings.TrimSpace(line) == "" {
			splitIdx = i
			break
		}
	}

	// parse ranges (first section)
	var ranges []idRange
	for _, line := range lines[:splitIdx] {
		parts := strings.Split(line, "-")
		// ParseInt returns (value, error) - we ignore errors here
		start, _ := strconv.ParseInt(parts[0], 10, 64)
		end, _ := strconv.ParseInt(parts[1], 10, 64)
		ranges = append(ranges, idRange{start, end})
	}

	// parse ingredient IDs (second section)
	var ingredients []int64
	for _, line := range lines[splitIdx+1:] {
		if strings.TrimSpace(line) != "" {
			id, _ := strconv.ParseInt(line, 10, 64)
			ingredients = append(ingredients, id)
		}
	}

	return ranges, ingredients
}

func main() {
	ranges, ingredients := loadInput("input.txt")

	// Part 1: count fresh ingredients (those in ANY range)
	part1 := 0
	for _, ing := range ingredients {
		if inRange(ing, ranges) {
			part1++
		}
	}
	fmt.Printf("Part 1: %d\n", part1)

	// Part 2: count ALL unique IDs covered by merged ranges
	merged := mergeRanges(ranges)

	var part2 int64 = 0
	for _, r := range merged {
		// each range covers (end - start + 1) unique IDs
		part2 += r.end - r.start + 1
	}
	fmt.Printf("Part 2: %d\n", part2)
}
