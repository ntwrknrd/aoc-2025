# Advent of Code 2025

## Branch Structure

| Branch   | Language | Worktree Directory |
|----------|----------|--------------------|
| `main`   | Template | `aoc-2025/`        |
| `python` | Python   | `aoc-2025-python/` |
| `golang` | Go       | `aoc-2025-go/`     |
| `rust`   | Rust     | `aoc-2025-rust/`   |
| `zig`    | Zig      | `aoc-2025-zig/`    |

## Inputs

Puzzles and their inputs are stored on `main` branch and shared across all language branches:
- `day01/input.txt`
- `day02/input.txt`
- etc.

## Usage

Solutions are first written in Python, then ported to other languages for practice and comparison. Each language implementation includes educational comments explaining language-specific concepts and idioms.

Git worktrees allow working on all languages in parallel without branch switching.

### Working on a language

```bash
# Switch to a language directory
cd ../aoc-2025-go

# Work on solutions, then commit
git add day01/solution.go
git commit -m "Solve day 1"
```

### Adding new puzzle inputs

When a new day is released, inputs are added to `main` and merged into language branches:

```bash
# In aoc-2025/ (main branch)
mkdir day04
# Add input.txt and puzzle.txt

git add -A
git commit -m "Add day 4 inputs"

# Then merge into all language worktrees at once
git worktree list --porcelain | grep '^worktree' | grep -v '/aoc-2025$' | cut -d' ' -f2 | xargs -I{} git -C {} merge main -m "Merge main"

# Push all branches to remote
git push origin --all
```

### Committing each day

```bash
git worktree list --porcelain | grep '^worktree' | grep -v '/aoc-2025$' | cut -d' ' -f2 | xargs -I{} sh -c 'git -C {} add -A && git -C {} commit -m "Day X " || true'
```
