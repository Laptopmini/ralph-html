#!/bin/bash

LEDGER=$(tail -n 5 .agent-ledger.jsonl)
PRD=$(cat PRD.md)

opencode run "
Read the following PRD. For each unchecked task, generate exactly the files described in that task — no more, no less.

- DO NOT write application source code. Only write config files and test files.
- Treat each checkbox item as a single atomic unit of work.
  - When finished, each task should have only a single file to execute to validate the task.
- Infer the correct tool and test type from the task description itself:
    - If the task involves a UI, leverage Playwright, write a .spec.ts file.
    - If the task involves only code logic, leverage Jest, write a .test.js file.
    - If the task involves running a script or CLI tool, either leverage an typechecking or linting tool, or write a small shell script in `scripts/`.
- Use ONLY data-testid attributes as element selectors. Do not assume class names, routing paths, or component structure beyond what the PRD states.
- Assert on: visibility, text content, ARIA roles, and keyboard focus where relevant to the task.
- Tests should fail against a blank implementation — avoid trivially passing assertions (e.g. no expect(true).toBe(true)).
- Sanity tests must contain the minimum assertion described — do not expand them.
- Each test file must cover the following:
    - The primary happy path
    - The most likely failure or edge case
- All generated tests must FAIL if the task is not complete, such as having zero implementation code.
- Use a beforeEach block for any shared setup (navigation, auth state).

--- ARCHITECTURAL HISTORY (Last 5 Entries) ---

$LEDGER_CONTEXT

--- PRD ---

$PRD
"

echo "✅ Tests generated. Please review them, ensure they fail but complete, and then run Ralph."