// Advent of Code 2025 - Day 12: Christmas Tree Farm (polyomino packing)
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Cell represents a position in a shape or grid.
// Go doesn't have tuples, so we use a struct instead.
type Cell struct {
	Row, Col int
}

// Shape is a set of cells. We use map[Cell]struct{} as Go's idiomatic "set" -
// struct{} takes zero bytes, so it's more memory efficient than map[Cell]bool.
type Shape map[Cell]struct{}

// Region holds the dimensions and required shape counts for a tree region
type Region struct {
	Width, Height int
	Counts        []int
}

// normalize shifts a shape so its top-left is at (0,0)
func normalize(shape Shape) Shape {
	if len(shape) == 0 {
		return shape
	}

	// find min row and col
	minRow, minCol := 1000, 1000
	for cell := range shape {
		if cell.Row < minRow {
			minRow = cell.Row
		}
		if cell.Col < minCol {
			minCol = cell.Col
		}
	}

	// shift everything
	result := make(Shape)
	for cell := range shape {
		result[Cell{cell.Row - minRow, cell.Col - minCol}] = struct{}{}
	}
	return result
}

// rotate90 rotates a shape 90 degrees clockwise: (r, c) -> (c, -r)
func rotate90(shape Shape) Shape {
	result := make(Shape)
	for cell := range shape {
		result[Cell{cell.Col, -cell.Row}] = struct{}{}
	}
	return normalize(result)
}

// flipHorizontal mirrors a shape: (r, c) -> (r, -c)
func flipHorizontal(shape Shape) Shape {
	result := make(Shape)
	for cell := range shape {
		result[Cell{cell.Row, -cell.Col}] = struct{}{}
	}
	return normalize(result)
}

// shapeToString converts a shape to a string for use as a map key.
// Go maps can't use slices or maps as keys, so we serialize to compare shapes.
func shapeToString(shape Shape) string {
	// collect cells and sort them for consistent ordering
	cells := make([]Cell, 0, len(shape))
	for cell := range shape {
		cells = append(cells, cell)
	}

	// simple bubble sort - shapes are tiny (7 cells max)
	for i := 0; i < len(cells); i++ {
		for j := i + 1; j < len(cells); j++ {
			if cells[i].Row > cells[j].Row ||
				(cells[i].Row == cells[j].Row && cells[i].Col > cells[j].Col) {
				cells[i], cells[j] = cells[j], cells[i]
			}
		}
	}

	var sb strings.Builder
	for _, c := range cells {
		fmt.Fprintf(&sb, "%d,%d;", c.Row, c.Col)
	}
	return sb.String()
}

// getAllOrientations returns all unique orientations (up to 8) of a shape
func getAllOrientations(shape Shape) []Shape {
	seen := make(map[string]struct{})
	var orientations []Shape

	current := shape
	for i := 0; i < 4; i++ {
		// try normal and flipped
		for _, s := range []Shape{current, flipHorizontal(current)} {
			normalized := normalize(s)
			key := shapeToString(normalized)
			if _, exists := seen[key]; !exists {
				seen[key] = struct{}{}
				orientations = append(orientations, normalized)
			}
		}
		current = rotate90(current)
	}

	return orientations
}

// parseShape converts lines like "###", "##.", ".##" into a Shape
func parseShape(lines []string) Shape {
	shape := make(Shape)
	for row, line := range lines {
		for col, ch := range line {
			if ch == '#' {
				shape[Cell{row, col}] = struct{}{}
			}
		}
	}
	return shape
}

// parseInput reads the puzzle input and returns shapes (with all orientations) and regions
func parseInput(filename string) (map[int][]Shape, []Region, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, nil, err
	}
	defer file.Close()

	shapes := make(map[int][]Shape)
	var regions []Region

	scanner := bufio.NewScanner(file)
	var currentLines []string
	var currentShapeIdx int = -1

	for scanner.Scan() {
		line := scanner.Text()

		// blank line ends current shape definition
		if line == "" {
			if currentShapeIdx >= 0 && len(currentLines) > 0 {
				shape := parseShape(currentLines)
				shapes[currentShapeIdx] = getAllOrientations(shape)
				currentLines = nil
				currentShapeIdx = -1
			}
			continue
		}

		// shape definition starts with "N:"
		if len(line) >= 2 && line[len(line)-1] == ':' {
			idx, err := strconv.Atoi(line[:len(line)-1])
			if err == nil {
				currentShapeIdx = idx
				currentLines = nil
				continue
			}
		}

		// region definition has "x" in dimensions
		if strings.Contains(line, "x") && strings.Contains(line, ": ") {
			parts := strings.SplitN(line, ": ", 2)
			dims := strings.Split(parts[0], "x")
			width, _ := strconv.Atoi(dims[0])
			height, _ := strconv.Atoi(dims[1])

			countStrs := strings.Fields(parts[1])
			counts := make([]int, len(countStrs))
			for i, s := range countStrs {
				counts[i], _ = strconv.Atoi(s)
			}

			regions = append(regions, Region{width, height, counts})
			continue
		}

		// otherwise it's part of a shape definition
		if currentShapeIdx >= 0 {
			currentLines = append(currentLines, line)
		}
	}

	// handle last shape if file doesn't end with blank line
	if currentShapeIdx >= 0 && len(currentLines) > 0 {
		shape := parseShape(currentLines)
		shapes[currentShapeIdx] = getAllOrientations(shape)
	}

	return shapes, regions, scanner.Err()
}

// Grid tracks which cells are occupied
type Grid struct {
	cells  [][]bool
	Height int
	Width  int
}

func newGrid(height, width int) *Grid {
	cells := make([][]bool, height)
	for i := range cells {
		cells[i] = make([]bool, width)
	}
	return &Grid{cells, height, width}
}

// canPlace checks if shape fits at (startRow, startCol) without overlapping
func (g *Grid) canPlace(shape Shape, startRow, startCol int) bool {
	for cell := range shape {
		r, c := startRow+cell.Row, startCol+cell.Col
		if r < 0 || r >= g.Height || c < 0 || c >= g.Width {
			return false
		}
		if g.cells[r][c] {
			return false
		}
	}
	return true
}

// place marks cells as occupied (fill=true) or empty (fill=false)
func (g *Grid) place(shape Shape, startRow, startCol int, fill bool) {
	for cell := range shape {
		g.cells[startRow+cell.Row][startCol+cell.Col] = fill
	}
}

// shapeInstance pairs a shape index with its possible orientations
type shapeInstance struct {
	idx          int
	orientations []Shape
}

// canPlaceAll uses backtracking to try placing all shapes on the grid
func canPlaceAll(toPlace []shapeInstance, grid *Grid) bool {
	// base case - everything placed!
	if len(toPlace) == 0 {
		return true
	}

	// grab next shape to place
	current := toPlace[0]
	remaining := toPlace[1:]

	// try each orientation at each position
	for _, orientation := range current.orientations {
		for row := 0; row < grid.Height; row++ {
			for col := 0; col < grid.Width; col++ {
				if grid.canPlace(orientation, row, col) {
					grid.place(orientation, row, col, true)

					if canPlaceAll(remaining, grid) {
						return true
					}

					// backtrack
					grid.place(orientation, row, col, false)
				}
			}
		}
	}

	return false
}

// canFitRegion checks if all required shapes fit in the region
func canFitRegion(shapes map[int][]Shape, region Region) bool {
	// quick check: enough cells?
	totalCells := 0
	for idx, count := range region.Counts {
		if count > 0 {
			if orientations, ok := shapes[idx]; ok && len(orientations) > 0 {
				totalCells += count * len(orientations[0])
			}
		}
	}

	if totalCells > region.Width*region.Height {
		return false
	}

	// build list of shapes to place
	var toPlace []shapeInstance
	for idx, count := range region.Counts {
		for i := 0; i < count; i++ {
			toPlace = append(toPlace, shapeInstance{idx, shapes[idx]})
		}
	}

	grid := newGrid(region.Height, region.Width)
	return canPlaceAll(toPlace, grid)
}

func main() {
	shapes, regions, err := parseInput("day12/input.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Part 1: count regions that can fit all presents
	count := 0
	for _, region := range regions {
		if canFitRegion(shapes, region) {
			count++
		}
	}

	fmt.Printf("Part 1: %d\n", count)
}
