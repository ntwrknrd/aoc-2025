"""Advent of Code 2025 - Day 1: Secret Entrance"""


def parse_rotation(rotation: str) -> tuple[str, int]:
    """Split 'L68' into direction and distance."""
    # grab the direction (L or R) and the number of clicks
    direction = rotation[0]
    distance = int(rotation[1:])  # everything after the first char
    return direction, distance


def apply_rotation(position: int, direction: str, distance: int) -> int:
    """Rotate the dial and return the new position."""
    if direction == "L":
        new_position = position - distance
    else:
        new_position = position + distance

    # wrap around using mod - the dial only goes 0-99
    return new_position % 100


def solve(rotations: list[str]) -> int:
    """Part 1: Count how many times the dial lands on 0 after a rotation."""
    position = 50  # dial starts at 50
    zero_count = 0

    for rotation in rotations:
        direction, distance = parse_rotation(rotation)
        position = apply_rotation(position, direction, distance)
        if position == 0:
            zero_count += 1

    return zero_count


def count_zeros_crossed(start: int, direction: str, distance: int) -> int:
    """
    Count how many times we pass through 0 during a rotation.

    The trick: instead of simulating each click one by one (slow!), we figure out
    the range of positions we traverse, then count how many multiples of 100 fall
    in that range. Why 100? Because 0, 100, -100, 200, etc. all equal 0 mod 100.
    """
    if direction == "L":
        # going left means we hit start-1, start-2, ... down to start-distance
        a = start - distance
        b = start - 1
    else:
        # going right means we hit start+1, start+2, ... up to start+distance
        a = start + 1
        b = start + distance

    # count multiples of 100 in the range [a, b]
    return b // 100 - (a - 1) // 100


def solve_part2(rotations: list[str]) -> int:
    """Part 2: Count ALL times the dial points at 0 - during AND after rotations."""
    position = 50
    zero_count = 0

    for rotation in rotations:
        direction, distance = parse_rotation(rotation)
        # count zeros we pass through during this rotation
        zero_count += count_zeros_crossed(position, direction, distance)
        position = apply_rotation(position, direction, distance)

    return zero_count


def load_input(filename: str) -> list[str]:
    """Read rotations from a file, one per line."""
    with open(filename) as f:
        return [line.strip() for line in f]


# test with the example from the puzzle
example_input = ["L68", "L30", "R48", "L5", "R60", "L55", "L1", "L99", "R14", "L82"]


if __name__ == "__main__":
    # Part 1
    print("--- Part 1 ---")
    result = solve(example_input)
    print(f"Example: {result}")  # should be 3

    real_input = load_input("input.txt")
    answer = solve(real_input)
    print(f"Answer:  {answer}")

    # Part 2
    print("\n--- Part 2 ---")
    result2 = solve_part2(example_input)
    print(f"Example: {result2}")  # should be 6

    answer2 = solve_part2(real_input)
    print(f"Answer:  {answer2}")
