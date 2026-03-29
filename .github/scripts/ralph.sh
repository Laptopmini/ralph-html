#!/bin/bash

# ==============================================================================
# RALPH LOOP: MULTI-ENGINE WITH TARGETED BACKPRESSURE
# Supports Anthropic's `claude` and the open-source `opencode`.
# Default Engine: claude
# Usage: ./ralph.sh [claude|opencode]
# ==============================================================================

# Settings
ARCHIVE_FOLDER=".prds"
LOCK_FILE=".ralph.lock"

# Options
ENGINE="claude"
MAX_LOOPS=10

# Variables
LOOP_COUNTER=0

if [ -e "$LOCK_FILE" ]; then
    echo "Error: Ralph Loop is already running! Exiting..."
    exit 1
fi

touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

if [[ -n "$1" && "$1" != --* ]]; then
    MAX_LOOPS="$1"
    shift
fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --engine)
      ENGINE="$2"
      if [[ "$ENGINE" != "claude" && "$ENGINE" != "opencode" ]]; then
        echo "Error: Unsupported engine '$ENGINE'. Use './ralph.sh --engine claude' or './ralph.sh --engine opencode'."
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

if [ ! -f PRD.md ]; then
    echo "Error: PRD.md not found."
    exit 1
fi

echo "🚀 Starting Ralph Loop for at most $MAX_LOOPS iterations, using $ENGINE..."

while true; do
    echo "------------------------- Iteration $LOOP_COUNTER/$MAX_LOOPS -------------------------"
    echo "Parsing Active Task & Target Test..."

    CURRENT_TASK=$(grep -m 1 "^\s*- \[ \]" PRD.md)

    if [ -z "$CURRENT_TASK" ]; then
        echo "No incomplete tasks found in PRD.md. Cleaning up..."

        rm -rf MEMORY.md

        echo "Archiving PRD..."
        mkdir -p "$ARCHIVE_FOLDER"

        COUNTER=0
        while [[ -f "$ARCHIVE_FOLDER/PRD.$COUNTER.md" ]]; do
            ((COUNTER++))
        done

        ARCHIVE_PATH="$ARCHIVE_FOLDER/PRD.$COUNTER.md"
        mv PRD.md "$ARCHIVE_PATH"
        echo "PRD archived to: $ARCHIVE_PATH"
        break
    fi

    if [[ "$LOOP_COUNTER" -ge "$MAX_LOOPS" ]]; then
        echo "⚠️ Max loops reached!"
        break
    fi

    LOOP_COUNTER=$((LOOP_COUNTER+1))

    echo "Active Task: $CURRENT_TASK"

    TARGETED_TEST=$(echo "$CURRENT_TASK" | sed -n 's/.*`\[test: \(.*\)\]`.*/\1/p')

    if [ -z "$TARGETED_TEST" ]; then
        echo "No targeted test found for this task. Defaulting to full suite."
        TARGETED_TEST="npm test"
    else
        echo "Targeted Backpressure Found: $TARGETED_TEST"
    fi

    echo "Assembling Context Window..."

    RALPH_PROMPT=$(cat .github/prompts/ralph.md 2>/dev/null || echo "You are an autonomous developer.")
    LEDGER_CONTEXT=$(tail -n 5 .agent-ledger.jsonl 2>/dev/null || echo "No history.")
    MEMORY_CONTEXT=$(cat MEMORY.md 2>/dev/null || echo "Scratchpad empty.")
    PRD_CONTENT=$(cat PRD.md)
    ERROR_FEEDBACK=""

    PROMPT="
$RALPH_PROMPT
$ERROR_FEEDBACK

--- ARCHITECTURAL HISTORY (Last 5 Entries) ---

$LEDGER_CONTEXT

--- YOUR PREVIOUS NOTES (MEMORY.md) ---

$MEMORY_CONTEXT

--- YOUR CURRENT TASK (PRD.md) ---

$PRD_CONTENT
"

    echo "Handing control to $ENGINE..."
    OUTPUT=""
    if [[ "$ENGINE" == "claude" ]]; then
        OUTPUT=$(claude -p "$PROMPT")
        if [[ "$OUTPUT" == *"rate_limit_error"* ]] || [[ "$OUTPUT" == *"insufficient_quota"* ]] || [[ "$OUTPUT" == *"credit balance"* ]]; then
            echo "Claude rate limit exceeded. Waiting for 1 hour..."
            sleep 3600 # 1 hour
            LOOP_COUNTER=$((LOOP_COUNTER-1))
            continue
        fi
    else
        OUTPUT=$(opencode run "$PROMPT")
    fi

    echo "Agent finished. Extracting proposed state updates..."
    PROPOSED_MEMORY=$(echo "$OUTPUT" | awk '/<memory>/{flag=1; next} /<\/memory>/{flag=0} flag')
    PROPOSED_LEDGER=$(echo "$OUTPUT" | awk '/<ledger>/{flag=1; next} /<\/ledger>/{flag=0} flag')

    echo "Running Validation: $TARGETED_TEST"
    TEST_OUTPUT=$(eval "$TARGETED_TEST" 2>&1)
    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -eq 0 ]; then
        echo "✅ Task passed! Continuing..."
        
        if [ -n "$PROPOSED_MEMORY" ]; then
            echo "$PROPOSED_MEMORY" > MEMORY.md
        fi
        
        if [ -n "$PROPOSED_LEDGER" ]; then
            echo "$PROPOSED_LEDGER" >> .agent-ledger.jsonl
        fi

        ESCAPED_TASK=$(echo "$CURRENT_TASK" | sed 's/[]\/$*.^[]/\\&/g')
        sed -i "s/$ESCAPED_TASK/- [x] ${CURRENT_TASK#*- [ ] }/" PRD.md
        
        git add .
        git commit -m "chore(ai): $ESCAPED_TASK"
        
        ERROR_FEEDBACK="" 
    else
        echo "❌ Validation failed. The agent must try again."

        ERROR_FEEDBACK="
        YOUR LAST ATTEMPT FAILED!
        You tried to complete the task, but the validation test failed.
        
        Test Command: $TARGETED_TEST
        Exit Code: $TEST_EXIT_CODE
        
        Test Output / Error Logs:
        $TEST_OUTPUT
        
        Please analyze the error, fix the code, and try again.
        "
    fi

    echo "Restarting loop in 3 seconds..."
    sleep 3
done

echo "👋 Ralph Loop ended!"
