"""Advent of Code 2025 - Day 4: Printing Department"""


def count_neighbors(grid: list[str], row: int, col: int) -> int:
    """Count how many @ symbols are adjacent to this cell (8 directions)."""
    rows = len(grid)
    cols = len(grid[0])
    count = 0

    # check all 8 directions: up, down, left, right, and diagonals
    for dr in [-1, 0, 1]:
        for dc in [-1, 0, 1]:
            if dr == 0 and dc == 0:
                continue  # skip the cell itself

            nr, nc = row + dr, col + dc

            # make sure we're still inside the grid
            if 0 <= nr < rows and 0 <= nc < cols:
                if grid[nr][nc] == '@':
                    count += 1

    return count


def find_accessible(grid: list[list[str]]) -> list[tuple[int, int]]:
    """Find all rolls that can be accessed (fewer than 4 adjacent rolls)."""
    accessible = []

    for row in range(len(grid)):
        for col in range(len(grid[0])):
            if grid[row][col] == '@':
                neighbors = count_neighbors(grid, row, col)
                if neighbors < 4:
                    accessible.append((row, col))

    return accessible


def solve(grid: list[str]) -> int:
    """Part 1: Count rolls accessible by forklift."""
    return len(find_accessible([list(row) for row in grid]))


def solve_part2(grid: list[str]) -> int:
    """Part 2: Keep removing accessible rolls until none left, count total removed."""
    # convert to mutable grid (list of lists instead of list of strings)
    grid = [list(row) for row in grid]
    total_removed = 0

    while True:
        accessible = find_accessible(grid)
        if not accessible:
            break  # no more rolls can be removed

        # remove all accessible rolls
        for row, col in accessible:
            grid[row][col] = '.'

        total_removed += len(accessible)

    return total_removed


# example from the puzzle
example_input = [
    "..@@.@@@@.",
    "@@@.@.@.@@",
    "@@@@@.@.@@",
    "@.@@@@..@.",
    "@@.@@@@.@@",
    ".@@@@@@@.@",
    ".@.@.@.@@@",
    "@.@@@.@@@@",
    ".@@@@@@@@.",
    "@.@.@@@.@.",
]


if __name__ == "__main__":
    with open("input.txt") as f:
        real_input = [line.strip() for line in f if line.strip()]

    # Part 1
    print("--- Part 1 ---")
    result = solve(example_input)
    print(f"Example: {result}")  # should be 13
    answer = solve(real_input)
    print(f"Answer:  {answer}")

    # Part 2
    print("\n--- Part 2 ---")
    result2 = solve_part2(example_input)
    print(f"Example: {result2}")  # should be 43
    answer2 = solve_part2(real_input)
    print(f"Answer:  {answer2}")
