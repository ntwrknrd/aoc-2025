// Advent of Code 2025 - Day 10: Factory (toggling lights & joltage counters)
//
// Part 1: Toggle lights with buttons to match a target pattern. Since toggling
// twice cancels out (XOR), each button is pressed 0 or 1 times optimally.
//
// Part 2: Counters that accumulate - buttons can be pressed multiple times.
// This becomes an Integer Linear Programming problem solved with matrix math.

use nalgebra::{DMatrix, DVector};
use regex::Regex;
use std::fs;

// holds parsed data for one factory machine
struct Machine {
    target: Vec<bool>,      // goal light state (true = on)
    buttons: Vec<Vec<i32>>, // each button lists which indices it affects
    joltages: Vec<i32>,     // target counter values for part 2
}

fn parse_line(line: &str) -> Machine {
    // grab the target pattern like [.##.] - dots are off, # are on
    let light_re = Regex::new(r"\[([.#]+)\]").unwrap();
    let target: Vec<bool> = light_re
        .captures(line)
        .map(|c| c[1].chars().map(|ch| ch == '#').collect())
        .unwrap_or_default();

    // grab all button definitions like (1,3) or (0,2,3,4)
    // each button lists which lights/counters it affects
    let button_re = Regex::new(r"\(([0-9,]+)\)").unwrap();
    let buttons: Vec<Vec<i32>> = button_re
        .captures_iter(line)
        .map(|c| c[1].split(',').filter_map(|s| s.parse().ok()).collect())
        .collect();

    // grab joltages from {curly braces} - the target values for part 2
    let jolt_re = Regex::new(r"\{([0-9,]+)\}").unwrap();
    let joltages: Vec<i32> = jolt_re
        .captures(line)
        .map(|c| c[1].split(',').filter_map(|s| s.parse().ok()).collect())
        .unwrap_or_default();

    Machine {
        target,
        buttons,
        joltages,
    }
}

// simulate pressing a subset of buttons (by bitmask) and return light state
fn apply_buttons(num_lights: usize, mask: usize, buttons: &[Vec<i32>]) -> Vec<bool> {
    let mut state = vec![false; num_lights];

    // for each bit set in mask, toggle the corresponding button's lights
    for (btn_idx, btn) in buttons.iter().enumerate() {
        if mask & (1 << btn_idx) != 0 {
            for &light in btn {
                let idx = light as usize;
                if idx < num_lights {
                    state[idx] = !state[idx];
                }
            }
        }
    }
    state
}

// find minimum button presses to match target lights using bitmask brute force.
// since toggling twice cancels, each button is used 0 or 1 times - try all 2^n combos.
fn find_min_presses(m: &Machine) -> i32 {
    let num_buttons = m.buttons.len();
    let num_lights = m.target.len();
    let total = 1 << num_buttons; // 2^num_buttons possible combinations

    // try subsets from smallest to largest - first match wins
    for target_count in 0..=num_buttons {
        for mask in 0..total {
            // count_ones() gives us the popcount (number of 1 bits)
            if (mask as u32).count_ones() as usize == target_count {
                let result = apply_buttons(num_lights, mask, &m.buttons);
                if result == m.target {
                    return target_count as i32;
                }
            }
        }
    }
    -1
}

fn solve_part1(machines: &[Machine]) -> i32 {
    machines.iter().map(find_min_presses).sum()
}

// --- Part 2: Integer Linear Programming via matrix math ---

// generate all k-combinations of indices 0..n-1
fn combinations(n: usize, k: usize) -> Vec<Vec<usize>> {
    if k > n {
        return vec![];
    }

    let mut result = Vec::new();
    let mut combo = vec![0; k];

    fn generate(
        start: usize,
        idx: usize,
        n: usize,
        k: usize,
        combo: &mut Vec<usize>,
        result: &mut Vec<Vec<usize>>,
    ) {
        if idx == k {
            result.push(combo.clone());
            return;
        }
        // the upper bound ensures we have room for remaining elements
        for i in start..=(n - (k - idx)) {
            combo[idx] = i;
            generate(i + 1, idx + 1, n, k, combo, result);
        }
    }

    generate(0, 0, n, k, &mut combo, &mut result);
    result
}

// check if a float is close to a non-negative integer, return it if so
fn is_nonneg_integer(x: f64) -> Option<i32> {
    if x < -1e-6 {
        return None;
    }
    let rounded = x.round() as i32;
    if rounded < 0 {
        return None;
    }
    if (x - rounded as f64).abs() > 1e-6 {
        return None;
    }
    Some(rounded)
}

// verify that pressing buttons the given number of times produces the target joltages
fn verify_solution(
    joltages: &[i32],
    buttons: &[Vec<i32>],
    subset: &[usize],
    presses: &[i32],
) -> bool {
    // iterate with enumerate to get both index and target value
    for (counter, &target) in joltages.iter().enumerate() {
        let sum: i32 = subset
            .iter()
            .zip(presses.iter())
            .map(|(&btn_idx, &p)| {
                if buttons[btn_idx].contains(&(counter as i32)) {
                    p
                } else {
                    0
                }
            })
            .sum();
        if sum != target {
            return false;
        }
    }
    true
}

// solve system with one more variable than equations (underdetermined).
// the free variable lets us parametrize solutions as: x_basic = x0 - coef*t
// returns (total_presses, solution_vector) if successful
fn solve_one_free_var(
    full_a: &[Vec<f64>],
    b: &[f64],
    subset: &[usize],
    free_idx: usize,
    max_val: i32,
) -> Option<(i32, Vec<i32>)> {
    let num_counters = b.len();

    // separate basic (to solve) and free (to enumerate) columns
    let basic_idx: Vec<usize> = (0..subset.len()).filter(|&i| i != free_idx).collect();

    // build square matrix for basic variables
    let basic_data: Vec<f64> = (0..num_counters)
        .flat_map(|i| basic_idx.iter().map(move |&j| full_a[i][subset[j]]))
        .collect();
    let basic_a = DMatrix::from_row_slice(num_counters, num_counters, &basic_data);

    // solve for x0 (the solution when free var = 0)
    let b_vec = DVector::from_column_slice(b);

    // nalgebra's lu().solve() returns None if singular
    let x0 = basic_a.clone().lu().solve(&b_vec)?;

    // solve for how basic vars change with free var: coef = A_basic^-1 * A_free
    let free_col: Vec<f64> = (0..num_counters)
        .map(|i| full_a[i][subset[free_idx]])
        .collect();
    let free_vec = DVector::from_column_slice(&free_col);
    let coef = basic_a.lu().solve(&free_vec)?;

    // find valid range for free variable t from constraint x_basic >= 0
    // when coef[i] > 0: t <= x0[i]/coef[i]
    // when coef[i] < 0: t >= x0[i]/coef[i]
    let mut t_min: f64 = 0.0;
    let mut t_max: f64 = max_val as f64;

    for i in 0..num_counters {
        let c = coef[i];
        let x = x0[i];
        if c > 1e-9 {
            t_max = t_max.min(x / c);
        } else if c < -1e-9 {
            t_min = t_min.max(x / c);
        } else if x < -1e-9 {
            return None; // infeasible
        }
    }

    if t_min > t_max + 1e-9 {
        return None;
    }

    // objective: minimize total = sum(x_basic) + t
    // total = sum(x0) + (1 - sum(coef)) * t
    let sum_coef: f64 = coef.iter().sum();
    let slope = 1.0 - sum_coef;

    // pick optimal integer t based on slope
    let opt_t = if slope > 1e-9 {
        t_min.ceil() as i32 // want smallest t
    } else if slope < -1e-9 {
        t_max.floor() as i32 // want largest t
    } else {
        t_min.ceil() as i32 // any valid t works
    };

    // clamp to valid range
    let opt_t = opt_t.max(t_min.ceil() as i32).min(t_max.floor() as i32);
    if opt_t < 0 {
        return None;
    }

    // build full solution vector: basic vars + free var at correct positions
    let subset_len = subset.len();
    let mut solution = vec![0i32; subset_len];
    let mut total = opt_t;

    // place free variable
    solution[free_idx] = opt_t;

    // place basic variables
    for (pos, &basic_pos) in basic_idx.iter().enumerate() {
        let val = x0[pos] - coef[pos] * opt_t as f64;
        let int_val = is_nonneg_integer(val)?;
        solution[basic_pos] = int_val;
        total += int_val;
    }

    Some((total, solution))
}

// handle systems with 1 or 2 free variables
fn solve_with_free_vars(
    full_a: &[Vec<f64>],
    b: &[f64],
    subset: &[usize],
    num_free: usize,
    max_val: i32,
    joltages: &[i32],
    buttons: &[Vec<i32>],
) -> Option<i32> {
    let num_counters = b.len();
    let subset_size = subset.len();

    if subset_size - num_free != num_counters {
        return None;
    }

    let mut best = i32::MAX;

    if num_free == 1 {
        // try each column as the free variable
        for free_idx in 0..subset_size {
            if let Some((total, solution)) =
                solve_one_free_var(full_a, b, subset, free_idx, max_val)
            {
                // verify solution actually works
                if verify_solution(joltages, buttons, subset, &solution) {
                    best = best.min(total);
                }
            }
        }
    } else if num_free == 2 {
        // for 2 free vars, enumerate one and solve the other analytically
        for free_idx1 in 0..subset_size {
            for free_idx2 in (free_idx1 + 1)..subset_size {
                // build sub-subset excluding first free var
                let sub_subset: Vec<usize> = (0..subset_size)
                    .filter(|&i| i != free_idx1)
                    .map(|i| subset[i])
                    .collect();

                // enumerate first free var, solve rest as 1-free-var system
                let cap = max_val.min(100);
                for fv1 in 0..=cap {
                    // adjust b for this fv1 value
                    let b_adj: Vec<f64> = (0..num_counters)
                        .map(|i| b[i] - full_a[i][subset[free_idx1]] * fv1 as f64)
                        .collect();

                    // relative position of free_idx2 in sub_subset (shifted by 1)
                    let rel_free_idx = free_idx2 - 1;

                    if let Some((sub_total, sub_solution)) =
                        solve_one_free_var(full_a, &b_adj, &sub_subset, rel_free_idx, max_val)
                    {
                        // build full solution by inserting fv1 at the right position
                        let mut full_solution = Vec::with_capacity(subset_size);
                        let mut sub_idx = 0;
                        for i in 0..subset_size {
                            if i == free_idx1 {
                                full_solution.push(fv1);
                            } else {
                                full_solution.push(sub_solution[sub_idx]);
                                sub_idx += 1;
                            }
                        }

                        // verify solution actually works
                        if verify_solution(joltages, buttons, subset, &full_solution) {
                            best = best.min(sub_total + fv1);
                        }
                    }
                }
            }
        }
    }

    if best == i32::MAX {
        None
    } else {
        Some(best)
    }
}

// find minimum presses to hit exact joltage values using linear algebra
fn find_min_joltage_presses(m: &Machine) -> i32 {
    let num_buttons = m.buttons.len();
    let num_counters = m.joltages.len();

    if num_buttons == 0 || num_counters == 0 {
        return 0;
    }

    // build incidence matrix: full_a[counter][button] = 1 if button affects counter
    let full_a: Vec<Vec<f64>> = (0..num_counters)
        .map(|counter| {
            let mut row = vec![0.0; num_buttons];
            for (btn_idx, btn) in m.buttons.iter().enumerate() {
                if btn.contains(&(counter as i32)) {
                    row[btn_idx] = 1.0;
                }
            }
            row
        })
        .collect();

    let max_jolt = *m.joltages.iter().max().unwrap_or(&100);
    let b: Vec<f64> = m.joltages.iter().map(|&j| j as f64).collect();

    let mut best = i32::MAX;

    // try subsets of buttons from size 1 up to num_counters+2
    let max_subset_size = (num_counters + 2).min(num_buttons);

    for size in 1..=max_subset_size {
        for subset in combinations(num_buttons, size) {
            let candidate = if size <= num_counters {
                // square or overdetermined - direct solve with nalgebra
                // build sub-matrix row by row
                let mut sub_data = Vec::with_capacity(num_counters * size);
                for row in full_a.iter().take(num_counters) {
                    for &btn_idx in &subset {
                        sub_data.push(row[btn_idx]);
                    }
                }
                let sub_a = DMatrix::from_row_slice(num_counters, size, &sub_data);
                let b_vec = DVector::from_column_slice(&b);

                // svd().solve() handles rectangular matrices (QR decomposition)
                let x = match sub_a.svd(true, true).solve(&b_vec, 1e-10) {
                    Ok(x) => x,
                    Err(_) => continue,
                };

                // verify solution is non-negative integers
                let solution: Option<Vec<i32>> =
                    (0..size).map(|j| is_nonneg_integer(x[j])).collect();
                let solution = match solution {
                    Some(s) => s,
                    None => continue,
                };

                // double-check Ax = b exactly (numerical stability guard)
                let mut valid = true;
                for (row, &target) in full_a.iter().zip(m.joltages.iter()) {
                    let sum: i32 = subset
                        .iter()
                        .zip(solution.iter())
                        .map(
                            |(&btn_idx, &presses)| {
                                if row[btn_idx] > 0.5 {
                                    presses
                                } else {
                                    0
                                }
                            },
                        )
                        .sum();
                    if sum != target {
                        valid = false;
                        break;
                    }
                }
                if !valid {
                    continue;
                }

                Some(solution.iter().sum())
            } else {
                // underdetermined - enumerate free variables
                let num_free = size - num_counters;
                solve_with_free_vars(
                    &full_a,
                    &b,
                    &subset,
                    num_free,
                    max_jolt,
                    &m.joltages,
                    &m.buttons,
                )
            };

            if let Some(c) = candidate {
                best = best.min(c);
            }
        }
    }

    if best == i32::MAX {
        -1
    } else {
        best
    }
}

fn solve_part2(machines: &[Machine]) -> i32 {
    machines.iter().map(find_min_joltage_presses).sum()
}

fn load_input(filename: &str) -> Vec<Machine> {
    let content = fs::read_to_string(filename).expect("couldn't read file");
    content
        .lines()
        .filter(|line| !line.trim().is_empty())
        .map(parse_line)
        .collect()
}

fn main() {
    let machines = load_input("input.txt");

    println!("--- Part 1 ---");
    let part1 = solve_part1(&machines);
    println!("Answer: {}", part1);

    println!("--- Part 2 ---");
    let part2 = solve_part2(&machines);
    println!("Answer: {}", part2);
}
