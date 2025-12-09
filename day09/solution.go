// Advent of Code 2025 - Day 9: Movie Theater (largest rectangle from tile corners)
package main

import (
	"bufio"
	"fmt"
	"math/bits"
	"os"
	"slices"
	"sort"
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

// VerticalEdge represents an edge going from (x, yLo) to (x, yHi)
type VerticalEdge struct {
	x, yLo, yHi int
}

// solvePart2 finds the largest rectangle with red corners where all tiles are valid.
// Uses sparse tables for O(1) range queries on the polygon's row-wise boundaries.
func solvePart2(tiles []Point) int64 {
	if len(tiles) < 2 {
		return 0
	}

	n := len(tiles)

	// build vertical edges from consecutive red tiles
	verticalEdges := make([]VerticalEdge, 0, n)
	for i := 0; i < n; i++ {
		x1, y1 := tiles[i].x, tiles[i].y
		x2, y2 := tiles[(i+1)%n].x, tiles[(i+1)%n].y
		if x1 == x2 {
			verticalEdges = append(verticalEdges, VerticalEdge{x1, min(y1, y2), max(y1, y2)})
		}
	}

	// collect unique y-values using map, then sort
	ySet := make(map[int]struct{})
	for _, p := range tiles {
		ySet[p.y] = struct{}{}
	}

	allYs := make([]int, 0, len(ySet))
	for y := range ySet {
		allYs = append(allYs, y)
	}
	sort.Ints(allYs) // use stdlib sort

	k := len(allYs)

	// compute left[y] and right[y] for each unique y
	leftArr := make([]int, k)
	rightArr := make([]int, k)

	for i, y := range allYs {
		// collect x's from edges spanning this row + tiles on this row
		xs := make([]int, 0, len(verticalEdges)+len(tiles))
		for _, edge := range verticalEdges {
			if edge.yLo <= y && y <= edge.yHi {
				xs = append(xs, edge.x)
			}
		}
		for _, p := range tiles {
			if p.y == y {
				xs = append(xs, p.x)
			}
		}

		// use slices.Min/Max (Go 1.21+)
		leftArr[i] = slices.Min(xs)
		rightArr[i] = slices.Max(xs)
	}

	// build flattened sparse tables using bits.Len for log2
	logK := bits.Len(uint(k))
	if logK == 0 {
		logK = 1
	}
	tableSize := logK * k
	sparse := make([]int, tableSize*2) // [maxLeft..., minRight...]

	// helper to index: table 0 = maxLeft, table 1 = minRight
	idx := func(table, level, pos int) int {
		return table*tableSize + level*k + pos
	}

	// initialize level 0
	for i := 0; i < k; i++ {
		sparse[idx(0, 0, i)] = leftArr[i]
		sparse[idx(1, 0, i)] = rightArr[i]
	}

	// build higher levels
	for j := 1; j < logK; j++ {
		half := 1 << (j - 1)
		step := half << 1
		if step > k {
			continue
		}
		for i := 0; i <= k-step; i++ {
			sparse[idx(0, j, i)] = max(sparse[idx(0, j-1, i)], sparse[idx(0, j-1, i+half)])
			sparse[idx(1, j, i)] = min(sparse[idx(1, j-1, i)], sparse[idx(1, j-1, i+half)])
		}
	}

	// query function using bits.Len for log2
	query := func(table, lo, hi int) int {
		length := hi - lo + 1
		j := bits.Len(uint(length)) - 1
		idx2 := hi - (1 << j) + 1
		if table == 0 {
			return max(sparse[idx(0, j, lo)], sparse[idx(0, j, idx2)])
		}
		return min(sparse[idx(1, j, lo)], sparse[idx(1, j, idx2)])
	}

	// check all pairs of red tiles
	var maxArea int64 = 0

	for i := 0; i < n; i++ {
		x1, y1 := tiles[i].x, tiles[i].y
		for j := i + 1; j < n; j++ {
			x2, y2 := tiles[j].x, tiles[j].y

			rxLo, rxHi := min(x1, x2), max(x1, x2)
			ryLo, ryHi := min(y1, y2), max(y1, y2)

			potential := int64(rxHi-rxLo+1) * int64(ryHi-ryLo+1)
			if potential <= maxArea {
				continue
			}

			// binary search for y indices (O(log k))
			iyLo := sort.SearchInts(allYs, ryLo)
			iyHi := sort.SearchInts(allYs, ryHi)

			ml := query(0, iyLo, iyHi)
			mr := query(1, iyLo, iyHi)

			if ml <= rxLo && mr >= rxHi {
				maxArea = potential
			}
		}
	}

	return maxArea
}

func loadInput(filename string) ([]Point, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, fmt.Errorf("opening file: %w", err)
	}
	defer file.Close()

	var tiles []Point
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		parts := strings.Split(line, ",")
		x, err := strconv.Atoi(parts[0])
		if err != nil {
			return nil, fmt.Errorf("parsing x: %w", err)
		}
		y, err := strconv.Atoi(parts[1])
		if err != nil {
			return nil, fmt.Errorf("parsing y: %w", err)
		}
		tiles = append(tiles, Point{x, y})
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("scanning: %w", err)
	}

	return tiles, nil
}

func main() {
	tiles, err := loadInput("day09/input.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("--- Part 1 ---")
	part1 := solve(tiles)
	fmt.Printf("Answer: %d\n", part1)

	fmt.Println("--- Part 2 ---")
	part2 := solvePart2(tiles)
	fmt.Printf("Answer: %d\n", part2)
}
