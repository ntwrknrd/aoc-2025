"""Advent of Code 2025 - Day 3: Lobby"""


def max_joltage(bank: str) -> int:
    """
    Find the maximum 2-digit joltage from a bank of batteries.

    Pick two batteries at positions i < j to form the number bank[i]bank[j].
    To maximize a 2-digit number, the tens digit matters most (it's worth 10x).

    We precompute suffix_max so we don't have to scan for the max digit every time.
    """
    n = len(bank)

    # suffix_max[i] = largest digit from position i to the end
    # build it backwards: start at the end, work left
    suffix_max = [0] * n
    suffix_max[-1] = int(bank[-1])
    for i in range(n - 2, -1, -1):
        suffix_max[i] = max(int(bank[i]), suffix_max[i + 1])

    # try each position as the tens digit, pair with best available units digit
    max_val = 0
    for i in range(n - 1):
        tens = int(bank[i])
        units = suffix_max[i + 1]  # best digit we can pick after position i
        candidate = tens * 10 + units
        max_val = max(max_val, candidate)

    return max_val


def solve(lines: list[str]) -> int:
    """Sum of maximum joltage from each bank."""
    return sum(max_joltage(line) for line in lines)


def max_joltage_k(bank: str, k: int) -> int:
    """
    Find the maximum k-digit joltage from a bank of batteries.

    Greedy approach: pick digits left to right, always grabbing the largest digit
    we can while still leaving enough digits for the rest of our number.

    Example with k=3 and bank="54321":
    - Need 3 digits total, so first pick from positions 0-2 (need room for 2 more)
    - Biggest in "543" is 5 at position 0
    - Now need 2 more, pick from positions 1-3
    - Biggest in "432" is 4 at position 1
    - Finally pick from positions 2-4, biggest is 3
    - Result: 543
    """
    n = len(bank)
    result = []
    start = 0  # where we can start looking for the next digit

    for i in range(k):
        remaining = k - i - 1  # how many more digits we need after this one
        end = n - remaining    # can't pick past here or we won't have room

        # find the largest digit in [start, end)
        best_pos = start
        for j in range(start + 1, end):
            if bank[j] > bank[best_pos]:
                best_pos = j

        result.append(bank[best_pos])
        start = best_pos + 1  # next pick has to come after this one

    return int(''.join(result))


def solve_part2(lines: list[str]) -> int:
    """Sum of maximum 12-digit joltage from each bank."""
    return sum(max_joltage_k(line, 12) for line in lines)


# example from the puzzle
example_input = [
    "987654321111111",
    "811111111111119",
    "234234234234278",
    "818181911112111",
]


if __name__ == "__main__":
    with open("input.txt") as f:
        real_input = [line.strip() for line in f if line.strip()]

    # Part 1
    print("--- Part 1 ---")
    result = solve(example_input)
    print(f"Example: {result}")  # should be 357
    answer = solve(real_input)
    print(f"Answer:  {answer}")

    # Part 2
    print("\n--- Part 2 ---")
    result2 = solve_part2(example_input)
    print(f"Example: {result2}")  # should be 3121910778619
    answer2 = solve_part2(real_input)
    print(f"Answer:  {answer2}")
