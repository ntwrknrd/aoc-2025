"""Day 12: Christmas Tree Farm - polyomino packing puzzle."""

from pathlib import Path


def parse_shape(lines: list[str]) -> set[tuple[int, int]]:
    """Convert a shape's visual representation to a set of (row, col) coordinates."""
    cells = set()
    for row, line in enumerate(lines):
        for col, char in enumerate(line):
            if char == "#":
                cells.add((row, col))
    return cells


def normalize(shape: set[tuple[int, int]]) -> frozenset[tuple[int, int]]:
    """Shift shape so its top-left corner is at (0, 0).

    This makes shapes comparable regardless of where they started.
    """
    if not shape:
        return frozenset()
    min_row = min(r for r, c in shape)
    min_col = min(c for r, c in shape)
    return frozenset((r - min_row, c - min_col) for r, c in shape)


def rotate_90(shape: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """Rotate shape 90 degrees clockwise.

    The trick: (row, col) -> (col, -row)
    Then we normalize to bring it back to origin.
    """
    return {(c, -r) for r, c in shape}


def flip_horizontal(shape: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """Flip shape horizontally (mirror across vertical axis)."""
    return {(r, -c) for r, c in shape}


def get_all_orientations(shape: set[tuple[int, int]]) -> list[frozenset[tuple[int, int]]]:
    """Generate all unique orientations of a shape (up to 8).

    4 rotations × 2 (original + flipped) = 8 max, but some shapes
    have symmetry so we use a set to dedupe.
    """
    orientations = set()
    current = shape

    # try all 4 rotations
    for _ in range(4):
        orientations.add(normalize(current))
        orientations.add(normalize(flip_horizontal(current)))
        current = rotate_90(current)

    return list(orientations)


def parse_input(text: str) -> tuple[dict[int, list[frozenset]], list[tuple[int, int, list[int]]]]:
    """Parse the full input into shapes and regions.

    Returns:
        shapes: dict mapping shape index -> list of all orientations
        regions: list of (width, height, [counts for each shape])
    """
    sections = text.strip().split("\n\n")

    shapes = {}
    regions = []

    for section in sections:
        lines = section.strip().split("\n")

        # check if this is a shape definition (starts with "N:")
        if lines[0].rstrip(":").isdigit() or (lines[0].endswith(":") and lines[0][:-1].isdigit()):
            # shape definition
            idx = int(lines[0].rstrip(":"))
            shape_cells = parse_shape(lines[1:])
            shapes[idx] = get_all_orientations(shape_cells)

        elif "x" in lines[0]:
            # region definitions - could be multiple lines
            for line in lines:
                parts = line.split(": ")
                dims = parts[0].split("x")
                width, height = int(dims[0]), int(dims[1])
                counts = list(map(int, parts[1].split()))
                regions.append((width, height, counts))

    return shapes, regions


def can_place_at(grid: list[list[bool]], shape: frozenset[tuple[int, int]],
                 start_row: int, start_col: int, height: int, width: int) -> bool:
    """Check if we can place a shape at the given position."""
    for dr, dc in shape:
        r, c = start_row + dr, start_col + dc
        # out of bounds?
        if r < 0 or r >= height or c < 0 or c >= width:
            return False
        # already occupied?
        if grid[r][c]:
            return False
    return True


def place_shape(grid: list[list[bool]], shape: frozenset[tuple[int, int]],
                start_row: int, start_col: int, fill: bool):
    """Place or remove a shape from the grid."""
    for dr, dc in shape:
        grid[start_row + dr][start_col + dc] = fill


def can_place_all_shapes(shapes_to_place: list[tuple[int, list[frozenset]]],
                         grid: list[list[bool]], height: int, width: int) -> bool:
    """Backtracking search to place all shapes on the grid."""
    # base case - all shapes placed successfully!
    if not shapes_to_place:
        return True

    # grab the next shape to place
    shape_idx, orientations = shapes_to_place[0]
    remaining = shapes_to_place[1:]

    # try each orientation of this shape
    for orientation in orientations:
        # try placing at each grid position
        for row in range(height):
            for col in range(width):
                if can_place_at(grid, orientation, row, col, height, width):
                    # place it and recurse
                    place_shape(grid, orientation, row, col, True)

                    if can_place_all_shapes(remaining, grid, height, width):
                        return True

                    # didn't work - backtrack by removing the shape
                    place_shape(grid, orientation, row, col, False)

    # no valid placement found for this shape
    return False


def can_fit_region(shapes: dict[int, list[frozenset]],
                   width: int, height: int, counts: list[int]) -> bool:
    """Check if all required shapes can fit in the region."""
    # quick check: do we even have enough cells?
    total_cells_needed = 0
    for idx, count in enumerate(counts):
        if count > 0 and idx in shapes:
            # all orientations have same cell count, just grab first
            total_cells_needed += count * len(shapes[idx][0])

    if total_cells_needed > width * height:
        return False

    # build list of shapes we need to place (one entry per shape instance)
    shapes_to_place = []
    for idx, count in enumerate(counts):
        for _ in range(count):
            shapes_to_place.append((idx, shapes[idx]))

    # start with empty grid
    grid = [[False] * width for _ in range(height)]

    return can_place_all_shapes(shapes_to_place, grid, height, width)


def main():
    text = (Path(__file__).parent / "input.txt").read_text()
    shapes, regions = parse_input(text)

    # Part 1: count regions that can fit all their presents
    count = 0
    for width, height, shape_counts in regions:
        if can_fit_region(shapes, width, height, shape_counts):
            count += 1

    print(f"Part 1: {count}")


if __name__ == "__main__":
    main()
