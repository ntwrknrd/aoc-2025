// Advent of Code 2025 - Day 8: Playground (connecting junction boxes with Union-Find)
package main

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
)

// UnionFind implements Disjoint Set Union with path compression and union by rank.
// Go doesn't have classes, but we can attach methods to structs.
type UnionFind struct {
	parent []int
	rank   []int
}

// NewUnionFind creates a Union-Find structure for n elements.
// Each element starts in its own set (parent points to itself).
func NewUnionFind(n int) *UnionFind {
	parent := make([]int, n)
	rank := make([]int, n)
	for i := range parent {
		parent[i] = i // each node is its own root initially
	}
	return &UnionFind{parent: parent, rank: rank}
}

// Find returns the root of x's set, with path compression.
// Path compression: make every node on the path point directly to the root.
func (uf *UnionFind) Find(x int) int {
	if uf.parent[x] != x {
		// recursive call + update parent = path compression
		uf.parent[x] = uf.Find(uf.parent[x])
	}
	return uf.parent[x]
}

// Union connects x and y's sets. Returns true if they were separate.
func (uf *UnionFind) Union(x, y int) bool {
	rootX := uf.Find(x)
	rootY := uf.Find(y)

	if rootX == rootY {
		return false // already in same set
	}

	// union by rank: attach smaller tree under larger
	if uf.rank[rootX] < uf.rank[rootY] {
		uf.parent[rootX] = rootY
	} else if uf.rank[rootX] > uf.rank[rootY] {
		uf.parent[rootY] = rootX
	} else {
		uf.parent[rootY] = rootX
		uf.rank[rootX]++
	}

	return true
}

// GetComponentSizes returns the size of each connected component.
func (uf *UnionFind) GetComponentSizes() []int {
	// count how many nodes share each root
	counts := make(map[int]int)
	for i := range uf.parent {
		root := uf.Find(i)
		counts[root]++
	}

	// extract just the sizes
	sizes := make([]int, 0, len(counts))
	for _, size := range counts {
		sizes = append(sizes, size)
	}
	return sizes
}

// Point3D represents a junction box position
type Point3D struct {
	x, y, z int
}

// Edge represents a potential connection between two junction boxes
type Edge struct {
	distSq int // squared distance (avoids sqrt)
	i, j   int // indices of the two points
}

// distanceSquared calculates squared Euclidean distance.
// We use squared distance to avoid sqrt - doesn't affect ordering.
func distanceSquared(a, b Point3D) int {
	dx := a.x - b.x
	dy := a.y - b.y
	dz := a.z - b.z
	return dx*dx + dy*dy + dz*dz
}

// solve connects numConnections shortest pairs, returns product of 3 largest circuits
func solve(points []Point3D, numConnections int) int {
	n := len(points)

	// generate all pairs with their distances
	var edges []Edge
	for i := 0; i < n; i++ {
		for j := i + 1; j < n; j++ {
			distSq := distanceSquared(points[i], points[j])
			edges = append(edges, Edge{distSq, i, j})
		}
	}

	// sort by distance
	sort.Slice(edges, func(a, b int) bool {
		return edges[a].distSq < edges[b].distSq
	})

	// connect the shortest pairs using Union-Find
	uf := NewUnionFind(n)
	for k := 0; k < numConnections && k < len(edges); k++ {
		uf.Union(edges[k].i, edges[k].j)
	}

	// find the 3 largest circuits
	sizes := uf.GetComponentSizes()
	sort.Sort(sort.Reverse(sort.IntSlice(sizes)))

	return sizes[0] * sizes[1] * sizes[2]
}

// solvePart2 connects until one circuit, returns X1 * X2 of the final connection
func solvePart2(points []Point3D) int64 {
	n := len(points)

	// generate all pairs with distances
	var edges []Edge
	for i := 0; i < n; i++ {
		for j := i + 1; j < n; j++ {
			distSq := distanceSquared(points[i], points[j])
			edges = append(edges, Edge{distSq, i, j})
		}
	}

	sort.Slice(edges, func(a, b int) bool {
		return edges[a].distSq < edges[b].distSq
	})

	// connect until we have one circuit (n-1 successful unions for n nodes)
	// this is essentially Kruskal's MST algorithm
	uf := NewUnionFind(n)
	unionsMade := 0
	var lastI, lastJ int

	for _, edge := range edges {
		if uf.Union(edge.i, edge.j) {
			unionsMade++
			lastI, lastJ = edge.i, edge.j
			// MST of n nodes has exactly n-1 edges
			if unionsMade == n-1 {
				break
			}
		}
	}

	// return product of X coordinates
	return int64(points[lastI].x) * int64(points[lastJ].x)
}

func loadInput(filename string) []Point3D {
	file, _ := os.Open(filename)
	defer file.Close()

	var points []Point3D
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// parse "x,y,z" format
		parts := strings.Split(line, ",")
		x, _ := strconv.Atoi(parts[0])
		y, _ := strconv.Atoi(parts[1])
		z, _ := strconv.Atoi(parts[2])
		points = append(points, Point3D{x, y, z})
	}

	return points
}

func main() {
	points := loadInput("day08/input.txt")

	fmt.Println("--- Part 1 ---")
	part1 := solve(points, 1000)
	fmt.Printf("Answer: %d\n", part1)

	fmt.Println("\n--- Part 2 ---")
	part2 := solvePart2(points)
	fmt.Printf("Answer: %d\n", part2)
}
