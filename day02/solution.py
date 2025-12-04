"""Advent of Code 2025 - Day 2: Gift Shop"""


def is_double(n: int) -> bool:
    """Check if a number is made of a digit sequence repeated twice (like 6464)."""
    s = str(n)
    if len(s) % 2 != 0:  # odd length can't be a double
        return False
    half = len(s) // 2
    return s[:half] == s[half:]


def generate_doubles_in_range(start: int, end: int) -> list[int]:
    """Find all double numbers in range by checking each candidate."""
    return [n for n in range(start, end + 1) if is_double(n)]


def is_repeating(n: int) -> bool:
    """Check if number is a pattern repeated 2+ times (111, 1212, 824824824)."""
    s = str(n)
    # try each possible pattern length that divides evenly
    for pattern_len in range(1, len(s) // 2 + 1):
        if len(s) % pattern_len == 0:
            pattern = s[:pattern_len]
            if pattern * (len(s) // pattern_len) == s:
                return True
    return False


def generate_repeating_in_range(start: int, end: int) -> list[int]:
    """Find all repeating-pattern numbers in range by checking each candidate."""
    return [n for n in range(start, end + 1) if is_repeating(n)]


def parse_input(line: str) -> list[tuple[int, int]]:
    """Parse comma-separated ranges like '11-22,95-115' into [(11,22), (95,115)]."""
    ranges = []
    for part in line.strip().split(','):
        start, end = part.split('-')
        ranges.append((int(start), int(end)))
    return ranges


def solve(input_line: str, finder_fn) -> int:
    """Sum all 'invalid' IDs found by finder_fn across all ranges."""
    ranges = parse_input(input_line)
    return sum(sum(finder_fn(start, end)) for start, end in ranges)


# example from the puzzle
example_input = "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124"


if __name__ == "__main__":
    with open("input.txt") as f:
        real_input = f.read().strip()

    # Part 1: doubles like 6464
    print("--- Part 1 ---")
    result = solve(example_input, generate_doubles_in_range)
    print(f"Example: {result}")  # should be 1227775554
    answer = solve(real_input, generate_doubles_in_range)
    print(f"Answer:  {answer}")

    # Part 2: any repeating pattern like 111, 1212, 824824824
    print("\n--- Part 2 ---")
    result2 = solve(example_input, generate_repeating_in_range)
    print(f"Example: {result2}")  # should be 4174379265
    answer2 = solve(real_input, generate_repeating_in_range)
    print(f"Answer:  {answer2}")
