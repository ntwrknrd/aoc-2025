"""Day 7: Laboratories - simulating tachyon beams through a splitter manifold."""

from pathlib import Path


def simulate_beams(grid: list[str]) -> int:
    """Simulate beams traveling down through the manifold, count splits."""
    # find where the beam enters (the 'S')
    start_col = grid[0].index("S")

    # track active beam positions as a set - handles merging automatically
    beams = {start_col}
    total_splits = 0

    # simulate each row from top to bottom
    for row in range(1, len(grid)):
        line = grid[row]
        new_beams = set()

        for col in beams:
            # check if this beam hits a splitter
            if col < len(line) and line[col] == "^":
                # beam hit a splitter! count it and spawn left/right
                total_splits += 1
                if col - 1 >= 0:
                    new_beams.add(col - 1)
                if col + 1 < len(line):
                    new_beams.add(col + 1)
            else:
                # empty space - beam continues straight down
                if 0 <= col < len(line):
                    new_beams.add(col)

        beams = new_beams

        # if no beams left, we're done
        if not beams:
            break

    return total_splits


def count_timelines(grid: list[str]) -> int:
    """Count distinct timelines using many-worlds interpretation."""
    start_col = grid[0].index("S")

    # now we track particle COUNTS at each position, not just presence
    # particles at same position are still distinct timelines
    particles = {start_col: 1}

    for row in range(1, len(grid)):
        line = grid[row]
        new_particles: dict[int, int] = {}

        for col, count in particles.items():
            if col < len(line) and line[col] == "^":
                # particle splits into two timelines (left and right)
                if col - 1 >= 0:
                    new_particles[col - 1] = new_particles.get(col - 1, 0) + count
                if col + 1 < len(line):
                    new_particles[col + 1] = new_particles.get(col + 1, 0) + count
            else:
                # continues down - preserves all timeline counts
                if 0 <= col < len(line):
                    new_particles[col] = new_particles.get(col, 0) + count

        particles = new_particles
        if not particles:
            break

    # total timelines = sum of all particle counts
    return sum(particles.values())


def main():
    text = (Path(__file__).parent / "input.txt").read_text()
    grid = text.strip().split("\n")

    part1 = simulate_beams(grid)
    print(f"Part 1: {part1}")

    part2 = count_timelines(grid)
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
