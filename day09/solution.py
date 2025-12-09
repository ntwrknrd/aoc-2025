"""Day 9: Movie Theater - finding the largest rectangle between red tiles."""

from collections import deque
from pathlib import Path


def solve_part1(tiles: list[tuple[int, int]]) -> int:
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


def solve_part2(red_tiles: list[tuple[int, int]]) -> int:
    """Find largest rectangle where corners are red and all tiles are red or green.

    The red tiles form a closed polygon. Green tiles fill the edges and interior.

    Key optimization: For a rectilinear polygon, each row y has a valid x-range
    [left[y], right[y]]. A rectangle is valid iff for all rows in its y-span,
    the rectangle's x-span is within that row's valid range.

    Uses coordinate compression + range queries for efficiency.
    """
    if len(red_tiles) < 2:
        return 0

    n = len(red_tiles)

    # build vertical edges (for computing valid x-ranges per row)
    vertical_edges = []
    for i in range(n):
        x1, y1 = red_tiles[i]
        x2, y2 = red_tiles[(i + 1) % n]
        if x1 == x2:  # vertical edge
            vertical_edges.append((x1, min(y1, y2), max(y1, y2)))

    # get all unique y values and their valid x-ranges
    # for a simple rectilinear polygon, each row has one contiguous valid interval
    all_ys = sorted(set(y for x, y in red_tiles))
    y_to_idx = {y: i for i, y in enumerate(all_ys)}

    # compute left[y] and right[y] for each unique y
    # left[y] = leftmost x in valid region, right[y] = rightmost
    left_arr = []
    right_arr = []

    for y in all_ys:
        # find x-coordinates where vertical edges cross this row
        # for interior points: edges where y_lo < y < y_hi
        # for boundary points: edges where y_lo <= y <= y_hi
        xs = []
        for ex, ey_lo, ey_hi in vertical_edges:
            if ey_lo <= y <= ey_hi:
                xs.append(ex)

        # also collect x's from red tiles on this row (boundary)
        for rx, ry in red_tiles:
            if ry == y:
                xs.append(rx)

        left_arr.append(min(xs))
        right_arr.append(max(xs))

    # build sparse tables for O(1) range-max(left) and range-min(right) queries
    k = len(all_ys)
    log_k = max(1, k.bit_length())

    # sparse table for range maximum of left[]
    max_left = [[0] * k for _ in range(log_k)]
    max_left[0] = left_arr[:]

    for j in range(1, log_k):
        step = 1 << j
        for i in range(k - step + 1):
            max_left[j][i] = max(max_left[j - 1][i], max_left[j - 1][i + (1 << (j - 1))])

    # sparse table for range minimum of right[]
    min_right = [[0] * k for _ in range(log_k)]
    min_right[0] = right_arr[:]

    for j in range(1, log_k):
        step = 1 << j
        for i in range(k - step + 1):
            min_right[j][i] = min(min_right[j - 1][i], min_right[j - 1][i + (1 << (j - 1))])

    def query_max_left(lo, hi):
        """Max of left[lo..hi] inclusive (using indices into all_ys)."""
        length = hi - lo + 1
        j = length.bit_length() - 1
        return max(max_left[j][lo], max_left[j][hi - (1 << j) + 1])

    def query_min_right(lo, hi):
        """Min of right[lo..hi] inclusive."""
        length = hi - lo + 1
        j = length.bit_length() - 1
        return min(min_right[j][lo], min_right[j][hi - (1 << j) + 1])

    # check all pairs of red tiles
    max_area = 0

    for i in range(n):
        x1, y1 = red_tiles[i]
        for j in range(i + 1, n):
            x2, y2 = red_tiles[j]

            # rectangle bounds
            rx_lo, rx_hi = min(x1, x2), max(x1, x2)
            ry_lo, ry_hi = min(y1, y2), max(y1, y2)

            # quick area check
            potential = (rx_hi - rx_lo + 1) * (ry_hi - ry_lo + 1)
            if potential <= max_area:
                continue

            # get y-index range
            iy_lo, iy_hi = y_to_idx[ry_lo], y_to_idx[ry_hi]

            # for rectangle to be valid:
            # max(left[y]) <= rx_lo  (all rows have left boundary <= our left edge)
            # min(right[y]) >= rx_hi (all rows have right boundary >= our right edge)
            ml = query_max_left(iy_lo, iy_hi)
            mr = query_min_right(iy_lo, iy_hi)

            if ml <= rx_lo and mr >= rx_hi:
                max_area = potential

    return max_area


def main():
    text = (Path(__file__).parent / "input.txt").read_text()

    tiles = []
    for line in text.strip().split("\n"):
        x, y = map(int, line.split(","))
        tiles.append((x, y))

    part1 = solve_part1(tiles)
    print(f"Part 1: {part1}")

    part2 = solve_part2(tiles)
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
