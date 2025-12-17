"""Day 10: Factory - toggling indicator lights with minimum button presses."""

import re
from itertools import combinations
from pathlib import Path

import numpy as np
from scipy.optimize import milp, LinearConstraint, Bounds


def parse_line(line: str) -> tuple[list[bool], list[set[int]], list[int]]:
    """Parse a machine line into its components.

    Returns (target_lights, buttons, joltages) where:
    - target_lights: list of bools for the goal state (True = on)
    - buttons: list of sets, each set contains which lights that button toggles
    - joltages: the numbers in curly braces (ignored for part 1)
    """
    # grab the target pattern like [.##.] - dots are off, # are on
    light_match = re.search(r'\[([.#]+)\]', line)
    light_str = light_match.group(1)
    target = [c == '#' for c in light_str]

    # grab all button definitions like (1,3) or (0,2,3,4)
    # each button lists which lights it toggles (0-indexed)
    button_matches = re.findall(r'\(([0-9,]+)\)', line)
    buttons = []
    for match in button_matches:
        indices = set(int(x) for x in match.split(','))
        buttons.append(indices)

    # grab joltages from {curly braces} - not needed for part 1 but parse anyway
    jolt_match = re.search(r'\{([0-9,]+)\}', line)
    joltages = [int(x) for x in jolt_match.group(1).split(',')]

    return target, buttons, joltages


def apply_buttons(num_lights: int, button_indices: list[int], buttons: list[set[int]]) -> list[bool]:
    """Apply a subset of buttons and return the resulting light state."""
    # start with all lights off
    state = [False] * num_lights

    # each button in our subset toggles its lights
    for btn_idx in button_indices:
        for light in buttons[btn_idx]:
            state[light] = not state[light]

    return state


def find_min_presses(target: list[bool], buttons: list[set[int]]) -> int:
    """Find minimum button presses to reach target state from all-off.

    Since pressing a button twice cancels out (XOR is self-inverse),
    each button is pressed 0 or 1 times in an optimal solution.
    We try all subset sizes starting from 0 - first match wins.
    """
    num_lights = len(target)
    num_buttons = len(buttons)

    # try subsets of increasing size - first one that works is minimal
    for size in range(num_buttons + 1):
        for combo in combinations(range(num_buttons), size):
            result = apply_buttons(num_lights, combo, buttons)
            if result == target:
                return size

    # shouldn't happen if puzzle is solvable
    return -1


def solve_part1(machines: list[tuple[list[bool], list[set[int]], list[int]]]) -> int:
    """Sum of minimum button presses across all machines."""
    total = 0
    for target, buttons, _ in machines:
        total += find_min_presses(target, buttons)
    return total


def find_min_joltage_presses(joltages: list[int], buttons: list[set[int]]) -> int:
    """Find minimum button presses to reach target joltage values.

    This is an Integer Linear Programming problem:
    - Variables: x_i = number of times button i is pressed (non-negative integer)
    - Constraint: for each counter j, sum of presses affecting it = target value
    - Objective: minimize total presses

    Uses scipy.optimize.milp for solving the ILP.
    """
    num_counters = len(joltages)
    num_buttons = len(buttons)

    # build the constraint matrix A where A[i][j] = 1 if button j affects counter i
    A = np.zeros((num_counters, num_buttons))
    for btn_idx, affected in enumerate(buttons):
        for counter in affected:
            if counter < num_counters:
                A[counter, btn_idx] = 1

    b = np.array(joltages, dtype=float)

    # objective: minimize sum of all presses (coefficient 1 for each variable)
    c = np.ones(num_buttons)

    # equality constraint: Ax = b (each counter must reach exactly its target)
    constraints = LinearConstraint(A, lb=b, ub=b)

    # all variables are non-negative integers
    # set a reasonable upper bound to help the solver
    max_press = max(joltages) if joltages else 100
    bounds = Bounds(lb=0, ub=max_press)

    # integrality: 1 means the variable must be an integer
    integrality = np.ones(num_buttons, dtype=int)

    result = milp(c, constraints=constraints, bounds=bounds, integrality=integrality)

    if result.success:
        return int(round(result.fun))
    else:
        return -1


def solve_part2(machines: list[tuple[list[bool], list[set[int]], list[int]]]) -> int:
    """Sum of minimum button presses for joltage configuration."""
    total = 0
    for _, buttons, joltages in machines:
        total += find_min_joltage_presses(joltages, buttons)
    return total


def main():
    text = (Path(__file__).parent / "input.txt").read_text()

    # the input has weird line numbering like "1→" at the start
    # strip that prefix if present
    machines = []
    for line in text.strip().split("\n"):
        # remove the "N→" prefix if it exists
        if "→" in line:
            line = line.split("→", 1)[1]
        machines.append(parse_line(line))

    part1 = solve_part1(machines)
    print(f"Part 1: {part1}")

    part2 = solve_part2(machines)
    print(f"Part 2: {part2}")


if __name__ == "__main__":
    main()
