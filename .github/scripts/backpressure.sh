#!/bin/bash

# ==============================================================================
# BACKPRESSURE GENERATOR: Generate tests based on current PRD
# Usage: ./backpressure.sh [--engine claude|opencode]
# ==============================================================================

set -euo pipefail

LEDGER=$(tail -n 5 .agent-ledger.jsonl || echo "No history.")
PRD=$(cat PRD.md)
ENGINE="claude"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --engine)
      ENGINE="$2"
      if [[ "$ENGINE" != "claude" && "$ENGINE" != "opencode" ]]; then
        echo "Error: Unsupported engine '$ENGINE'. Use '$0 --engine claude' or '$0 --engine opencode'."
        exit 1
      fi
      shift 2
      ;;
    *)
      echo "Error: Unknown argument '$1'."
      echo "Usage: $0 [MAX_LOOPS] [--engine claude|opencode]"
      exit 1
      ;;
  esac
done

if ! command -v $ENGINE &> /dev/null; then
    echo "Error: $ENGINE CLI is not installed."
    exit 1
fi

echo "🟢 Starting to generate backpressure..."

AGENT_PROMPT="
Read the following PRD. For each unchecked task, generate exactly the files described in that task — no more, no less.

Read package.json before generating tests to understand which dependencies and test runners are available.

You are running in non-interactive mode, if you have a question, pick the solution which does not break an existing constraint.

- DO NOT write application source code. Only write config files and test files.
- Treat each checkbox item as a single atomic unit of work.
  - When finished, each task should have only a single file to execute to validate the task.
  - If a task includes a \`[test: command]\` annotation, extract the file path and test runner from it.
  - The generated test file MUST match the exact path in the annotation (e.g., \`[test: npx jest tests/foo.test.ts]\` → create \`tests/foo.test.ts\`).
  - The test runner specified in the annotation (jest, playwright, etc.) takes precedence over any inference from the task description.
  - If no \`[test: ...]\` annotation is present, fall back to inferring the tool, type, and path from the task description.
- Infer the correct tool and test type from the task description itself:
    - If the task involves a UI, leverage Playwright, write a .spec.ts file.
    - If the task involves only code logic, leverage Jest, write a .test.ts file.
    - If the task involves running a script or CLI tool, either leverage an typechecking or linting tool, or write a small shell script in \`scripts/\`.
- Use ONLY data-testid attributes as element selectors. Do not assume class names, routing paths, or component structure beyond what the PRD states.
- Assert on: visibility, text content, ARIA roles, and keyboard focus where relevant to the task.
- Tests should fail against a blank implementation — avoid trivially passing assertions (e.g. no expect(true).toBe(true)).
- Sanity tests must contain the minimum assertion described — do not expand them.
- Each test file must cover the following:
    - The primary happy path
    - The most likely failure or edge case
- All generated tests must FAIL if the task is not complete, such as having zero implementation code.
- Use a beforeEach block for any shared setup (navigation, auth state).

When finished, run the following quality gates in order:
- \`npm run lint\` — auto-fixes lint & formatting issues. Manually resolve any issues that cannot be auto-fixed.
- \`npm run check-types\` — verifies TypeScript compilation. Fix any type errors before finishing.

Then finally, run the tests and assert non-zero exit code.

--- ARCHITECTURAL HISTORY (Last 5 Entries) ---

$LEDGER

--- PRD ---

$PRD
"

echo "🟡 Handing control to $ENGINE..."
if [[ "$ENGINE" == "claude" ]]; then
    claude -p "$AGENT_PROMPT" --allowedTools "Read,Write,Glob,Grep" --model claude-opus-4-6
else
    opencode run "$AGENT_PROMPT"
fi

echo "✅ Tests generated. Please review them, and then execute the Ralph loop."