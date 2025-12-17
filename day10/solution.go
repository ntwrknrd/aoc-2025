// Advent of Code 2025 - Day 10: Factory (toggling lights & joltage counters)
package main

import (
	"bufio"
	"fmt"
	"math"
	"math/bits"
	"os"
	"regexp"
	"strconv"
	"strings"

	"gonum.org/v1/gonum/mat"
)

// Machine holds parsed data for one factory machine
type Machine struct {
	target   []bool  // goal light state (true = on)
	buttons  [][]int // each button lists which indices it affects
	joltages []int   // target counter values for part 2
}

// parseLine extracts target lights, buttons, and joltages from a line like:
// [.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
func parseLine(line string) Machine {
	var m Machine

	// grab the target pattern like [.##.] - dots are off, # are on
	lightRe := regexp.MustCompile(`\[([.#]+)\]`)
	lightMatch := lightRe.FindStringSubmatch(line)
	if lightMatch != nil {
		for _, c := range lightMatch[1] {
			m.target = append(m.target, c == '#')
		}
	}

	// grab all button definitions like (1,3) or (0,2,3,4)
	buttonRe := regexp.MustCompile(`\(([0-9,]+)\)`)
	buttonMatches := buttonRe.FindAllStringSubmatch(line, -1)
	for _, match := range buttonMatches {
		var indices []int
		for _, s := range strings.Split(match[1], ",") {
			n, _ := strconv.Atoi(s)
			indices = append(indices, n)
		}
		m.buttons = append(m.buttons, indices)
	}

	// grab joltages from {curly braces}
	joltRe := regexp.MustCompile(`\{([0-9,]+)\}`)
	joltMatch := joltRe.FindStringSubmatch(line)
	if joltMatch != nil {
		for _, s := range strings.Split(joltMatch[1], ",") {
			n, _ := strconv.Atoi(s)
			m.joltages = append(m.joltages, n)
		}
	}

	return m
}

// applyButtons simulates pressing a subset of buttons (by bitmask) and returns light state
func applyButtons(numLights int, mask int, buttons [][]int) []bool {
	state := make([]bool, numLights)

	// for each bit set in mask, toggle the corresponding button's lights
	for btnIdx := 0; btnIdx < len(buttons); btnIdx++ {
		if mask&(1<<btnIdx) != 0 {
			for _, light := range buttons[btnIdx] {
				if light < numLights {
					state[light] = !state[light]
				}
			}
		}
	}
	return state
}

// slicesEqual checks if two bool slices match
func slicesEqual(a, b []bool) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// findMinPresses finds minimum button presses to match target lights.
// Since toggling twice cancels out, each button is pressed 0 or 1 times.
// We iterate masks in order of popcount (number of set bits).
func findMinPresses(m Machine) int {
	numButtons := len(m.buttons)
	numLights := len(m.target)
	total := 1 << numButtons

	// try subsets from smallest to largest - first hit wins
	for targetCount := 0; targetCount <= numButtons; targetCount++ {
		for mask := 0; mask < total; mask++ {
			if bits.OnesCount(uint(mask)) == targetCount {
				result := applyButtons(numLights, mask, m.buttons)
				if slicesEqual(result, m.target) {
					return targetCount
				}
			}
		}
	}
	return -1
}

// solvePart1 sums minimum button presses for all machines (light toggling)
func solvePart1(machines []Machine) int {
	total := 0
	for _, m := range machines {
		total += findMinPresses(m)
	}
	return total
}

// combinations generates all k-combinations of indices 0..n-1
func combinations(n, k int) [][]int {
	if k > n || k < 0 {
		return nil
	}
	var result [][]int
	combo := make([]int, k)

	var generate func(start, idx int)
	generate = func(start, idx int) {
		if idx == k {
			c := make([]int, k)
			copy(c, combo)
			result = append(result, c)
			return
		}
		for i := start; i <= n-(k-idx); i++ {
			combo[idx] = i
			generate(i+1, idx+1)
		}
	}
	generate(0, 0)
	return result
}

// isNonNegativeInteger checks if x is close to a non-negative integer
func isNonNegativeInteger(x float64) (int, bool) {
	if x < -1e-6 {
		return 0, false
	}
	rounded := int(math.Round(x))
	if rounded < 0 {
		return 0, false
	}
	if math.Abs(x-float64(rounded)) > 1e-6 {
		return 0, false
	}
	return rounded, true
}

// solveOneFreeVar solves a system with one more variable than equations.
// Uses analytical approach: x_basic = x0 - coef*t, finds optimal integer t.
func solveOneFreeVar(fullA [][]float64, b []float64, subset []int, freeIdx int, maxVal int) (int, bool) {
	numCounters := len(b)
	subsetSize := len(subset)

	// separate basic and free columns
	basicIdx := make([]int, 0, numCounters)
	for i := 0; i < subsetSize; i++ {
		if i != freeIdx {
			basicIdx = append(basicIdx, i)
		}
	}

	// build square matrix for basic variables
	basicData := make([]float64, numCounters*numCounters)
	for i := 0; i < numCounters; i++ {
		for j, bIdx := range basicIdx {
			basicData[i*numCounters+j] = fullA[i][subset[bIdx]]
		}
	}
	basicA := mat.NewDense(numCounters, numCounters, basicData)

	// solve for x0 (when t=0)
	bVec := mat.NewVecDense(numCounters, b)
	var x0 mat.VecDense
	if err := x0.SolveVec(basicA, bVec); err != nil {
		return 0, false
	}

	// solve for coefficient: how basic vars change with t
	// x_basic = x0 - coef*t, where coef = A_basic^-1 * A_free
	freeCol := make([]float64, numCounters)
	for i := 0; i < numCounters; i++ {
		freeCol[i] = fullA[i][subset[freeIdx]]
	}
	freeVec := mat.NewVecDense(numCounters, freeCol)
	var coef mat.VecDense
	if err := coef.SolveVec(basicA, freeVec); err != nil {
		return 0, false
	}

	// find bounds on t from x_basic >= 0: x0[i] - coef[i]*t >= 0
	tMin := 0.0
	tMax := float64(maxVal)
	for i := 0; i < numCounters; i++ {
		c := coef.AtVec(i)
		x := x0.AtVec(i)
		if c > 1e-9 {
			// t <= x/c
			bound := x / c
			if bound < tMax {
				tMax = bound
			}
		} else if c < -1e-9 {
			// t >= x/c (note: c is negative, so direction flips)
			bound := x / c
			if bound > tMin {
				tMin = bound
			}
		} else if x < -1e-9 {
			return 0, false // infeasible
		}
	}

	if tMin > tMax+1e-9 {
		return 0, false
	}

	// total = sum(x0) - sum(coef)*t + t = sum(x0) + (1-sum(coef))*t
	sumX0 := 0.0
	sumCoef := 0.0
	for i := 0; i < numCounters; i++ {
		sumX0 += x0.AtVec(i)
		sumCoef += coef.AtVec(i)
	}
	slope := 1 - sumCoef

	// find optimal integer t
	var optT int
	if slope > 1e-9 {
		optT = int(math.Ceil(tMin)) // want smallest t
	} else if slope < -1e-9 {
		optT = int(math.Floor(tMax)) // want largest t
	} else {
		optT = int(math.Ceil(tMin)) // any valid t
	}

	// clamp to valid range
	if float64(optT) < tMin-1e-9 {
		optT = int(math.Ceil(tMin))
	}
	if float64(optT) > tMax+1e-9 {
		optT = int(math.Floor(tMax))
	}
	if optT < 0 {
		return 0, false
	}

	// build and verify solution
	total := optT
	for i := 0; i < numCounters; i++ {
		val := x0.AtVec(i) - coef.AtVec(i)*float64(optT)
		intVal, ok := isNonNegativeInteger(val)
		if !ok {
			return 0, false
		}
		total += intVal
	}

	return total, true
}

// solveWithFreeVars handles underdetermined systems.
func solveWithFreeVars(fullA [][]float64, b []float64, subset []int, numFree int, maxVal int) (int, bool) {
	numCounters := len(b)
	subsetSize := len(subset)

	if subsetSize-numFree != numCounters {
		return 0, false
	}

	best := math.MaxInt32

	if numFree == 1 {
		// try each column as the free variable
		for freeIdx := 0; freeIdx < subsetSize; freeIdx++ {
			if total, ok := solveOneFreeVar(fullA, b, subset, freeIdx, maxVal); ok {
				if total < best {
					best = total
				}
			}
		}
	} else if numFree == 2 {
		// for 2 free vars, enumerate one and solve for the other analytically
		for freeIdx1 := 0; freeIdx1 < subsetSize; freeIdx1++ {
			for freeIdx2 := freeIdx1 + 1; freeIdx2 < subsetSize; freeIdx2++ {
				// build sub-subset excluding both free vars
				subSubset := make([]int, 0, numCounters+1)
				for i := 0; i < subsetSize; i++ {
					if i != freeIdx1 {
						subSubset = append(subSubset, subset[i])
					}
				}

				// enumerate freeIdx1, solve rest as 1-free-var system
				cap := maxVal
				if cap > 100 {
					cap = 100
				}
				for fv1 := 0; fv1 <= cap; fv1++ {
					// adjust b for this fv1 value
					bAdj := make([]float64, numCounters)
					for i := 0; i < numCounters; i++ {
						bAdj[i] = b[i] - fullA[i][subset[freeIdx1]]*float64(fv1)
					}

					// find relative position of freeIdx2 in subSubset
					relFreeIdx := freeIdx2 - 1 // since freeIdx1 < freeIdx2

					if total, ok := solveOneFreeVar(fullA, bAdj, subSubset, relFreeIdx, maxVal); ok {
						total += fv1
						if total < best {
							best = total
						}
					}
				}
			}
		}
	}

	if best == math.MaxInt32 {
		return 0, false
	}
	return best, true
}

// findMinJoltagePresses finds minimum presses to reach exact joltage values.
// Strategy: try subsets of buttons, solve the linear system (handling
// underdetermined cases by enumerating free variables).
func findMinJoltagePresses(m Machine) int {
	numButtons := len(m.buttons)
	numCounters := len(m.joltages)

	if numButtons == 0 || numCounters == 0 {
		return 0
	}

	// build full incidence matrix: fullA[counter][button] = 1 if button affects counter
	fullA := make([][]float64, numCounters)
	for i := range fullA {
		fullA[i] = make([]float64, numButtons)
	}
	for btnIdx, btn := range m.buttons {
		for _, counter := range btn {
			if counter < numCounters {
				fullA[counter][btnIdx] = 1
			}
		}
	}

	// find max joltage for bounding free variable search
	maxJolt := 0
	for _, j := range m.joltages {
		if j > maxJolt {
			maxJolt = j
		}
	}

	b := make([]float64, numCounters)
	for i, j := range m.joltages {
		b[i] = float64(j)
	}

	best := math.MaxInt32

	// try subsets from size 1 up to numCounters+2 (as original did)
	maxSubsetSize := numCounters + 2
	if maxSubsetSize > numButtons {
		maxSubsetSize = numButtons
	}

	for size := 1; size <= maxSubsetSize; size++ {
		for _, subset := range combinations(numButtons, size) {
			var candidate int
			var ok bool

			if size <= numCounters {
				// square or overdetermined - gonum handles both via QR decomposition
				subData := make([]float64, numCounters*size)
				for i := 0; i < numCounters; i++ {
					for j, btnIdx := range subset {
						subData[i*size+j] = fullA[i][btnIdx]
					}
				}
				subA := mat.NewDense(numCounters, size, subData)
				bVec := mat.NewVecDense(numCounters, b)

				var x mat.VecDense
				if err := x.SolveVec(subA, bVec); err != nil {
					continue
				}

				// verify solution is non-negative integers
				solution := make([]int, size)
				valid := true
				for j := 0; j < size; j++ {
					val, vok := isNonNegativeInteger(x.AtVec(j))
					if !vok {
						valid = false
						break
					}
					solution[j] = val
				}
				if !valid {
					continue
				}

				// verify Ax = b exactly (guards against numerical error)
				for i := 0; i < numCounters; i++ {
					sum := 0
					for j, btnIdx := range subset {
						sum += int(fullA[i][btnIdx]) * solution[j]
					}
					if sum != m.joltages[i] {
						valid = false
						break
					}
				}
				if !valid {
					continue
				}

				candidate = 0
				for _, v := range solution {
					candidate += v
				}
				ok = true
			} else {
				// underdetermined - enumerate free variables
				numFree := size - numCounters
				candidate, ok = solveWithFreeVars(fullA, b, subset, numFree, maxJolt)
			}

			if ok && candidate < best {
				best = candidate
			}
		}
	}

	if best == math.MaxInt32 {
		return -1
	}
	return best
}

// solvePart2 sums minimum button presses for all machines (joltage counters)
func solvePart2(machines []Machine) int {
	total := 0
	for _, m := range machines {
		total += findMinJoltagePresses(m)
	}
	return total
}

func loadInput(filename string) ([]Machine, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, fmt.Errorf("opening file: %w", err)
	}
	defer file.Close()

	var machines []Machine
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		machines = append(machines, parseLine(line))
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("scanning: %w", err)
	}

	return machines, nil
}

func main() {
	machines, err := loadInput("day10/input.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("--- Part 1 ---")
	part1 := solvePart1(machines)
	fmt.Printf("Answer: %d\n", part1)

	fmt.Println("--- Part 2 ---")
	part2 := solvePart2(machines)
	fmt.Printf("Answer: %d\n", part2)
}
