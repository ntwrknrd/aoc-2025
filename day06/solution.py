"""Day 6: Trash Compactor - parsing a cephalopod's math worksheet."""

from pathlib import Path


def find_problem_boundaries(lines: list[str]) -> list[tuple[int, int]]:
    """Find where each problem starts and ends by looking for separator columns."""
    # pad all lines to same width so we can scan columns cleanly
    width = max(len(line) for line in lines)
    padded = [line.ljust(width) for line in lines]

    # a separator column is one where ALL rows are spaces
    # we'll mark each column as True (separator) or False (part of a problem)
    is_separator = []
    for col in range(width):
        all_spaces = all(row[col] == " " for row in padded)
        is_separator.append(all_spaces)

    # now group consecutive non-separator columns into problem ranges
    # each problem is a (start_col, end_col) tuple
    problems = []
    start = None
    for col, sep in enumerate(is_separator):
        if not sep and start is None:
            # found the start of a new problem
            start = col
        elif sep and start is not None:
            # found the end of a problem
            problems.append((start, col))
            start = None

    # don't forget the last problem if it runs to the edge
    if start is not None:
        problems.append((start, width))

    return problems


def parse_worksheet(lines: list[str]) -> list[tuple[list[int], str]]:
    """Parse the worksheet into a list of (numbers, operator) tuples."""
    # last row has the operators, everything else is numbers
    operator_row = lines[-1]
    number_rows = lines[:-1]

    # pad for consistent column access
    width = max(len(line) for line in lines)
    padded_numbers = [row.ljust(width) for row in number_rows]
    operator_row = operator_row.ljust(width)

    problems = find_problem_boundaries(lines)

    result = []
    for start, end in problems:
        # grab all numbers from this column range
        numbers = []
        for row in padded_numbers:
            chunk = row[start:end].strip()
            if chunk:
                numbers.append(int(chunk))

        # the operator is buried in this column range too
        op_chunk = operator_row[start:end].strip()
        operator = op_chunk if op_chunk in "+*" else "+"

        result.append((numbers, operator))

    return result


def parse_worksheet_cephalopod(lines: list[str]) -> list[tuple[list[int], str]]:
    """Parse the worksheet cephalopod-style: digits in columns, read right-to-left."""
    operator_row = lines[-1]
    number_rows = lines[:-1]

    width = max(len(line) for line in lines)
    padded_numbers = [row.ljust(width) for row in number_rows]
    operator_row = operator_row.ljust(width)

    problems = find_problem_boundaries(lines)

    result = []
    for start, end in problems:
        # extract the rectangular chunk for this problem
        chunks = [row[start:end] for row in padded_numbers]
        chunk_width = end - start

        # read columns right-to-left - each column of digits becomes one number
        numbers = []
        for col in range(chunk_width - 1, -1, -1):  # right to left
            digits = ""
            for row in chunks:
                char = row[col] if col < len(row) else " "
                if char.isdigit():
                    digits += char
            if digits:
                numbers.append(int(digits))

        op_chunk = operator_row[start:end].strip()
        operator = op_chunk if op_chunk in "+*" else "+"

        result.append((numbers, operator))

    return result


def solve_part1(problems: list[tuple[list[int], str]]) -> int:
    """Solve each problem and return the grand total."""
    total = 0
    for numbers, operator in problems:
        if operator == "+":
            result = sum(numbers)
        else:  # multiplication
            result = 1
            for n in numbers:
                result *= n
        total += result
    return total


def main():
    text = (Path(__file__).parent / "input.txt").read_text()

    # preserve the raw line structure - don't strip trailing spaces yet!
    # we need them to find problem boundaries
    lines = text.split("\n")

    # drop any completely empty trailing lines
    while lines and not lines[-1]:
        lines.pop()

    problems = parse_worksheet(lines)
    part1 = solve_part1(problems)
    print(f"Part 1: {part1}")

    # part 2: cephalopod-style reading (columns = numbers, right-to-left)
    problems_v2 = parse_worksheet_cephalopod(lines)
    part2 = solve_part1(problems_v2)  # same solve logic, different parsing
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
