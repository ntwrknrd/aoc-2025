"""Day 5: Cafeteria - checking which ingredients are fresh based on ID ranges."""

from pathlib import Path


def main():
    text = (Path(__file__).parent / "input.txt").read_text()
    range_section, ingredient_section = text.strip().split("\n\n")

    # parse ranges as tuples of (start, end)
    ranges = [tuple(map(int, line.split("-"))) for line in range_section.split("\n")]

    # parse ingredient IDs
    ingredients = [int(line) for line in ingredient_section.split("\n")]

    # count fresh: ingredient is fresh if it falls in ANY range
    part1 = sum(
        any(start <= ing <= end for start, end in ranges) for ing in ingredients
    )
    print(f"Part 1: {part1}")

    # Part 2: count ALL unique IDs covered by the ranges (merge overlapping ranges)
    sorted_ranges = sorted(ranges)  # sort by start value (first element of tuple)

    # merge overlapping ranges
    merged = [sorted_ranges[0]]
    for start, end in sorted_ranges[1:]:
        prev_start, prev_end = merged[-1]
        # if this range overlaps or touches the previous one, extend it
        if start <= prev_end + 1:
            merged[-1] = (prev_start, max(prev_end, end))
        else:
            # no overlap, start a new merged range
            merged.append((start, end))

    # count total IDs: each range covers (end - start + 1) IDs
    part2 = sum(end - start + 1 for start, end in merged)
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
