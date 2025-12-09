"""Day 9: Movie Theater - finding the largest rectangle between red tiles."""

from pathlib import Path


def solve(tiles: list[tuple[int, int]]) -> int:
    """Find the largest rectangle using any two red tiles as opposite corners.

    O(n) approach: the optimal rectangle always involves "extreme" points.
    We track 8 extremes (4 axis-aligned + 4 diagonal) and check only those pairs.
    """
    if len(tiles) < 2:
        return 0

    # track extreme points in a single pass
    min_x_pt = max_x_pt = tiles[0]
    min_y_pt = max_y_pt = tiles[0]
    min_sum_pt = max_sum_pt = tiles[0]  # x+y extremes (diagonal)
    min_diff_pt = max_diff_pt = tiles[0]  # x-y extremes (anti-diagonal)

    for x, y in tiles:
        if x < min_x_pt[0]:
            min_x_pt = (x, y)
        if x > max_x_pt[0]:
            max_x_pt = (x, y)
        if y < min_y_pt[1]:
            min_y_pt = (x, y)
        if y > max_y_pt[1]:
            max_y_pt = (x, y)

        s, d = x + y, x - y
        if s < min_sum_pt[0] + min_sum_pt[1]:
            min_sum_pt = (x, y)
        if s > max_sum_pt[0] + max_sum_pt[1]:
            max_sum_pt = (x, y)
        if d < min_diff_pt[0] - min_diff_pt[1]:
            min_diff_pt = (x, y)
        if d > max_diff_pt[0] - max_diff_pt[1]:
            max_diff_pt = (x, y)

    # at most 8 unique candidates
    candidates = list(
        set(
            [
                min_x_pt,
                max_x_pt,
                min_y_pt,
                max_y_pt,
                min_sum_pt,
                max_sum_pt,
                min_diff_pt,
                max_diff_pt,
            ]
        )
    )

    # check all pairs among candidates (at most 28 pairs)
    max_area = 0
    for i in range(len(candidates)):
        for j in range(i + 1, len(candidates)):
            x1, y1 = candidates[i]
            x2, y2 = candidates[j]
            # +1 because tiles are squares - both corners included
            area = (abs(x2 - x1) + 1) * (abs(y2 - y1) + 1)
            max_area = max(max_area, area)

    return max_area


def main():
    text = (Path(__file__).parent / "input.txt").read_text()

    tiles = []
    for line in text.strip().split("\n"):
        x, y = map(int, line.split(","))
        tiles.append((x, y))

    part1 = solve(tiles)
    print(f"Part 1: {part1}")


if __name__ == "__main__":
    main()
