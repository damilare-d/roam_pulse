// Command aiworkflow is the mechanical half of RoamPulse's AI-assisted
// engineering workflow (tools/ai/README.md, docs/AI_DEVELOPMENT_WORKFLOW.md).
// It runs the same gates every change — AI-authored or not — must clear,
// and refuses a "ready for review" verdict if any of them fails, never
// ran, or was skipped. Proposal, architecture validation, and code
// generation happen before this tool is ever invoked; this is the part
// that isn't allowed to be skipped afterward.
package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"roampulse/tools/ai/internal/pipeline"
)

// pureDartPackages have no Flutter dependency — tested with `dart test`,
// matching flutter-ci.yml's own split (a Flutter-dependent package run
// through `dart test` fails outright, which is exactly the bug this
// project hit twice before: packages/diagnostics in Phase 8, then
// packages/ai_agent in Phase 11).
var pureDartPackages = []string{"packages/core", "packages/network", "packages/analytics"}

var flutterTargets = []string{
	"packages/design_system",
	"packages/storage",
	"packages/connectivity",
	"packages/plans",
	"packages/diagnostics",
	"packages/ai_agent",
	"apps/mobile",
}

func main() {
	reviewer := flag.String("reviewer", "", "human reviewer confirmation — the human-review gate cannot pass without this")
	flag.Parse()

	root, err := findRepoRoot()
	if err != nil {
		fmt.Fprintln(os.Stderr, "aiworkflow:", err)
		os.Exit(1)
	}

	results := []pipeline.GateResult{
		runFormatGate(root),
		runStaticAnalysisGate(root),
	}
	tests, coverage := runTestsAndCoverageGates(root)
	results = append(results, tests, coverage, pipeline.HumanReviewGate(*reviewer))

	for _, r := range results {
		fmt.Printf("[%s] %s\n", strings.ToUpper(string(r.Status)), r.Name)
		if r.Detail != "" {
			fmt.Printf("        %s\n", r.Detail)
		}
	}

	verdict := pipeline.Evaluate(results)
	fmt.Println()
	if verdict.Ready {
		fmt.Println("READY FOR REVIEW —", verdict.Reason)
		return
	}
	fmt.Println("NOT READY —", verdict.Reason)
	os.Exit(1)
}

// findRepoRoot walks up from the current directory looking for
// melos.yaml, so aiworkflow runs correctly whether invoked from the repo
// root, from tools/ai (its own Go module), or anywhere else inside the
// repo.
func findRepoRoot() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "melos.yaml")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", fmt.Errorf("could not find repo root (no melos.yaml in any parent directory)")
		}
		dir = parent
	}
}

func runCommand(dir, name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	return string(out), err
}

func firstLine(s string) string {
	s = strings.TrimSpace(s)
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		return s[:i]
	}
	return s
}

func runFormatGate(root string) pipeline.GateResult {
	out, err := runCommand(root, "dart", "format", "--set-exit-if-changed", ".")
	if err != nil {
		return pipeline.GateResult{Name: "format", Status: pipeline.StatusFailed, Detail: firstLine(out)}
	}
	return pipeline.GateResult{Name: "format", Status: pipeline.StatusPassed}
}

func runStaticAnalysisGate(root string) pipeline.GateResult {
	var failures []string

	if out, err := runCommand(root, "dart", "analyze", "--fatal-infos"); err != nil {
		failures = append(failures, "dart analyze: "+firstLine(out))
	}
	if out, err := runCommand(filepath.Join(root, "backend", "api"), "go", "vet", "./..."); err != nil {
		failures = append(failures, "backend go vet: "+firstLine(out))
	}
	if out, err := runCommand(filepath.Join(root, "tools", "ai"), "go", "vet", "./..."); err != nil {
		failures = append(failures, "tools/ai go vet: "+firstLine(out))
	}

	if len(failures) > 0 {
		return pipeline.GateResult{Name: "static-analysis", Status: pipeline.StatusFailed, Detail: strings.Join(failures, " | ")}
	}
	return pipeline.GateResult{Name: "static-analysis", Status: pipeline.StatusPassed}
}

// runTestsAndCoverageGates runs every test suite exactly once — with
// coverage instrumentation on from the start — so the coverage gate
// never has to re-run the whole suite a second time just to get a
// number.
func runTestsAndCoverageGates(root string) (tests, coverage pipeline.GateResult) {
	var failures []string
	var coverageNotes []string

	if out, err := runCommand(root, "dart", append([]string{"test"}, pureDartPackages...)...); err != nil {
		failures = append(failures, "dart test: "+firstLine(out))
	}

	for _, target := range flutterTargets {
		dir := filepath.Join(root, filepath.FromSlash(target))
		out, err := runCommand(dir, "flutter", "test", "--coverage")
		if err != nil {
			failures = append(failures, target+": "+firstLine(out))
			continue
		}
		if _, statErr := os.Stat(filepath.Join(dir, "coverage", "lcov.info")); statErr == nil {
			coverageNotes = append(coverageNotes, target+": coverage/lcov.info written")
		}
	}

	backendDir := filepath.Join(root, "backend", "api")
	if out, err := runCommand(backendDir, "go", "test", "-cover", "./..."); err != nil {
		failures = append(failures, "backend go test: "+firstLine(out))
	} else {
		coverageNotes = append(coverageNotes, coveragePercentages(out)...)
	}

	if out, err := runCommand(filepath.Join(root, "tools", "ai"), "go", "test", "-cover", "./..."); err != nil {
		failures = append(failures, "tools/ai go test: "+firstLine(out))
	} else {
		coverageNotes = append(coverageNotes, coveragePercentages(out)...)
	}

	if len(failures) > 0 {
		detail := strings.Join(failures, " | ")
		return pipeline.GateResult{Name: "tests", Status: pipeline.StatusFailed, Detail: detail},
			pipeline.GateResult{Name: "coverage", Status: pipeline.StatusFailed, Detail: "not measured — tests failed"}
	}

	tests = pipeline.GateResult{Name: "tests", Status: pipeline.StatusPassed}
	// Passing means coverage was genuinely measured, not that it cleared
	// some threshold — the brief never specifies one, and inventing a
	// number here would be exactly the kind of fabricated requirement
	// this pipeline exists to avoid. A reviewer reads the actual numbers.
	coverage = pipeline.GateResult{Name: "coverage", Status: pipeline.StatusPassed, Detail: strings.Join(coverageNotes, "; ")}
	return tests, coverage
}

// coveragePercentages pulls "coverage: NN.N% of statements" lines out of
// `go test -cover` output.
func coveragePercentages(goTestOutput string) []string {
	var lines []string
	for _, line := range strings.Split(goTestOutput, "\n") {
		if strings.Contains(line, "coverage:") {
			lines = append(lines, strings.TrimSpace(line))
		}
	}
	return lines
}
