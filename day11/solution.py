"""Day 11: Reactor - counting paths through a device network."""

from functools import cache
from pathlib import Path


def parse_input(text: str) -> dict[str, list[str]]:
    """Build a graph from the device list - each device maps to its outputs."""
    graph = {}
    for line in text.strip().split("\n"):
        if not line.strip():
            continue

        # format: "device: output1 output2 output3"
        parts = line.split(": ")
        device = parts[0]
        outputs = parts[1].split() if len(parts) > 1 else []
        graph[device] = outputs

    return graph


def make_path_counter(graph: dict[str, list[str]]):
    """Create a memoized path counter for the given graph.

    Returns a function that counts paths between any two nodes.
    The cache is shared across all calls, so repeated queries are fast.
    """

    @cache
    def count_paths(start: str, end: str) -> int:
        """Count all paths from start to end using memoized DFS."""
        # reached our destination - that's one valid path
        if start == end:
            return 1

        # dead end - this node doesn't lead anywhere
        if start not in graph:
            return 0

        # sum paths through all our outputs
        total = 0
        for neighbor in graph[start]:
            total += count_paths(neighbor, end)
        return total

    return count_paths


def count_paths_through_both(count_paths, start: str, end: str,
                              wp1: str, wp2: str) -> int:
    """Count paths from start to end that visit both waypoints.

    In a DAG, a valid path visits wp1 then wp2, or wp2 then wp1.
    We use the multiplication principle: paths(A->B->C) = paths(A->B) * paths(B->C)

    Since it's a DAG, you can't have cycles - so if there's a path from wp1 to wp2,
    there can't be a path from wp2 to wp1. One term will naturally be zero.
    """
    # paths that hit wp1 first, then wp2
    via_wp1_first = (count_paths(start, wp1) *
                     count_paths(wp1, wp2) *
                     count_paths(wp2, end))

    # paths that hit wp2 first, then wp1
    via_wp2_first = (count_paths(start, wp2) *
                     count_paths(wp2, wp1) *
                     count_paths(wp1, end))

    return via_wp1_first + via_wp2_first


def main():
    text = (Path(__file__).parent / "input.txt").read_text()
    graph = parse_input(text)

    # create a path counter with shared cache for all queries
    count_paths = make_path_counter(graph)

    part1 = count_paths("you", "out")
    print(f"Part 1: {part1}")

    part2 = count_paths_through_both(count_paths, "svr", "out", "dac", "fft")
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
