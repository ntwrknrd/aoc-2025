"""Day 8: Playground - connecting junction boxes with Union-Find."""

from pathlib import Path
from math import sqrt
from collections import Counter


class UnionFind:
    """Disjoint Set Union with path compression and union by rank."""

    def __init__(self, n: int):
        # each node starts as its own parent (its own circuit)
        self.parent = list(range(n))
        self.rank = [0] * n

    def find(self, x: int) -> int:
        """Find the root of x's circuit, with path compression."""
        if self.parent[x] != x:
            # path compression: point directly to root
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]

    def union(self, x: int, y: int) -> bool:
        """Connect x and y's circuits. Returns True if they were separate."""
        root_x = self.find(x)
        root_y = self.find(y)

        if root_x == root_y:
            # already in same circuit - nothing happens
            return False

        # union by rank: attach smaller tree under larger
        if self.rank[root_x] < self.rank[root_y]:
            self.parent[root_x] = root_y
        elif self.rank[root_x] > self.rank[root_y]:
            self.parent[root_y] = root_x
        else:
            self.parent[root_y] = root_x
            self.rank[root_x] += 1

        return True

    def get_component_sizes(self) -> list[int]:
        """Return sizes of all connected components."""
        # find root of each node, count how many nodes share each root
        roots = [self.find(i) for i in range(len(self.parent))]
        return list(Counter(roots).values())


def distance_squared(p1: tuple[int, int, int], p2: tuple[int, int, int]) -> int:
    """Squared Euclidean distance - avoids sqrt for comparison."""
    return (p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2 + (p1[2] - p2[2]) ** 2


def solve(points: list[tuple[int, int, int]], num_connections: int) -> int:
    """Connect num_connections shortest pairs, return product of 3 largest circuits."""
    n = len(points)

    # generate all pairs with their distances
    # use squared distance to avoid sqrt (doesn't affect ordering)
    pairs = []
    for i in range(n):
        for j in range(i + 1, n):
            dist_sq = distance_squared(points[i], points[j])
            pairs.append((dist_sq, i, j))

    # sort by distance
    pairs.sort()

    # connect the shortest pairs using Union-Find
    uf = UnionFind(n)
    for dist_sq, i, j in pairs[:num_connections]:
        uf.union(i, j)

    # find the 3 largest circuits
    sizes = sorted(uf.get_component_sizes(), reverse=True)
    return sizes[0] * sizes[1] * sizes[2]


def solve_part2(points: list[tuple[int, int, int]]) -> int:
    """Connect until one circuit, return X1 * X2 of the final connection."""
    n = len(points)

    # generate all pairs with distances
    pairs = []
    for i in range(n):
        for j in range(i + 1, n):
            dist_sq = distance_squared(points[i], points[j])
            pairs.append((dist_sq, i, j))

    pairs.sort()

    # connect until we have one circuit (n-1 successful unions for n nodes)
    uf = UnionFind(n)
    unions_made = 0
    last_i, last_j = -1, -1

    for dist_sq, i, j in pairs:
        if uf.union(i, j):
            unions_made += 1
            last_i, last_j = i, j
            # MST of n nodes has exactly n-1 edges
            if unions_made == n - 1:
                break

    # return product of X coordinates
    return points[last_i][0] * points[last_j][0]


def main():
    text = (Path(__file__).parent / "input.txt").read_text()

    # parse coordinates
    points = []
    for line in text.strip().split("\n"):
        x, y, z = map(int, line.split(","))
        points.append((x, y, z))

    part1 = solve(points, 1000)
    print(f"Part 1: {part1}")

    part2 = solve_part2(points)
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
