// Advent of Code 2025 - Day 9: Movie Theater (largest rectangle from tile corners)
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Point represents a red tile position on the grid
type Point struct {
	x, y int
}

// abs returns absolute value (Go doesn't have built-in int abs)
func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

// solve finds the largest rectangle using any two red tiles as opposite corners.
// O(n) approach: the optimal rectangle always involves "extreme" points.
func solve(tiles []Point) int64 {
	if len(tiles) < 2 {
		return 0
	}

	// track extreme points in a single pass
	minXPt, maxXPt := tiles[0], tiles[0]
	minYPt, maxYPt := tiles[0], tiles[0]
	minSumPt, maxSumPt := tiles[0], tiles[0]   // x+y extremes (diagonal)
	minDiffPt, maxDiffPt := tiles[0], tiles[0] // x-y extremes (anti-diagonal)

	for _, p := range tiles {
		// axis-aligned extremes
		if p.x < minXPt.x {
			minXPt = p
		}
		if p.x > maxXPt.x {
			maxXPt = p
		}
		if p.y < minYPt.y {
			minYPt = p
		}
		if p.y > maxYPt.y {
			maxYPt = p
		}

		// diagonal extremes
		sum := p.x + p.y
		diff := p.x - p.y
		if sum < minSumPt.x+minSumPt.y {
			minSumPt = p
		}
		if sum > maxSumPt.x+maxSumPt.y {
			maxSumPt = p
		}
		if diff < minDiffPt.x-minDiffPt.y {
			minDiffPt = p
		}
		if diff > maxDiffPt.x-maxDiffPt.y {
			maxDiffPt = p
		}
	}

	// collect unique candidates using a map
	seen := make(map[Point]bool)
	for _, p := range []Point{minXPt, maxXPt, minYPt, maxYPt, minSumPt, maxSumPt, minDiffPt, maxDiffPt} {
		seen[p] = true
	}

	candidates := make([]Point, 0, len(seen))
	for p := range seen {
		candidates = append(candidates, p)
	}

	// check all pairs among candidates (at most 28 pairs)
	var maxArea int64 = 0
	for i := 0; i < len(candidates); i++ {
		for j := i + 1; j < len(candidates); j++ {
			p1, p2 := candidates[i], candidates[j]
			// +1 because tiles are squares - both corners included
			width := int64(abs(p2.x-p1.x) + 1)
			height := int64(abs(p2.y-p1.y) + 1)
			area := width * height
			if area > maxArea {
				maxArea = area
			}
		}
	}

	return maxArea
}

func loadInput(filename string) []Point {
	file, _ := os.Open(filename)
	defer file.Close()

	var tiles []Point
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// parse "x,y" format
		parts := strings.Split(line, ",")
		x, _ := strconv.Atoi(parts[0])
		y, _ := strconv.Atoi(parts[1])
		tiles = append(tiles, Point{x, y})
	}

	return tiles
}

func main() {
	tiles := loadInput("day09/input.txt")

	fmt.Println("--- Part 1 ---")
	part1 := solve(tiles)
	fmt.Printf("Answer: %d\n", part1)
}
