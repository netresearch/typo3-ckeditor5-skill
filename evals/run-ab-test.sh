#!/usr/bin/env bash
# A/B eval runner: WITHOUT skill vs WITH skill
# Usage: ./evals/run-ab-test.sh [eval-index|all]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EVALS_FILE="$SCRIPT_DIR/evals.json"
RESULTS_DIR="$SCRIPT_DIR/results"
PLUGIN_DIR="$REPO_DIR/.claude-plugin"

mkdir -p "$RESULTS_DIR"

# Parse evals
EVAL_COUNT=$(python3 -c "import json; print(len(json.load(open('$EVALS_FILE'))))")

run_eval() {
  local idx=$1
  local eval_json
  eval_json=$(python3 -c "
import json
evals = json.load(open('$EVALS_FILE'))
e = evals[$idx]
print(json.dumps(e))
")
  local name prompt
  name=$(echo "$eval_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['name'])")
  prompt=$(echo "$eval_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])")

  echo "=== Eval $idx: $name ==="

  # WITHOUT skill (no plugin dir, no slash commands)
  echo "  Running WITHOUT skill..."
  local start_without end_without duration_without
  start_without=$(date +%s%N)
  local output_without
  output_without=$(cd /tmp && claude -p \
    --disable-slash-commands \
    --model sonnet \
    --no-session-persistence \
    --max-budget-usd 0.50 \
    "$prompt" 2>/dev/null) || output_without="ERROR"
  end_without=$(date +%s%N)
  duration_without=$(( (end_without - start_without) / 1000000 ))

  # WITH skill (plugin dir)
  echo "  Running WITH skill..."
  local start_with end_with duration_with
  start_with=$(date +%s%N)
  local output_with
  output_with=$(cd /tmp && claude -p \
    --disable-slash-commands \
    --model sonnet \
    --no-session-persistence \
    --max-budget-usd 0.50 \
    --plugin-dir "$PLUGIN_DIR" \
    "$prompt" 2>/dev/null) || output_with="ERROR"
  end_with=$(date +%s%N)
  duration_with=$(( (end_with - start_with) / 1000000 ))

  # Save outputs
  echo "$output_without" > "$RESULTS_DIR/${name}_without.txt"
  echo "$output_with" > "$RESULTS_DIR/${name}_with.txt"

  # Check assertions
  local assertions_json
  assertions_json=$(echo "$eval_json" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['assertions']))")

  local pass_without=0 pass_with=0 total_assertions
  total_assertions=$(echo "$assertions_json" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

  for aidx in $(seq 0 $((total_assertions - 1))); do
    local atype avalue
    atype=$(echo "$assertions_json" | python3 -c "import json,sys; print(json.load(sys.stdin)[$aidx]['type'])")
    avalue=$(echo "$assertions_json" | python3 -c "import json,sys; print(json.load(sys.stdin)[$aidx].get('value',''))")

    if [ "$atype" = "content_contains" ]; then
      if echo "$output_without" | grep -qi "$avalue" 2>/dev/null; then
        pass_without=$((pass_without + 1))
      fi
      if echo "$output_with" | grep -qi "$avalue" 2>/dev/null; then
        pass_with=$((pass_with + 1))
      fi
    fi
  done

  local words_without words_with
  words_without=$(echo "$output_without" | wc -w)
  words_with=$(echo "$output_with" | wc -w)

  echo "$name|$pass_without/$total_assertions|$pass_with/$total_assertions|$words_without|$words_with|${duration_without}ms|${duration_with}ms" >> "$RESULTS_DIR/ab-summary.csv"
  echo "  WITHOUT: $pass_without/$total_assertions assertions, $words_without words, ${duration_without}ms"
  echo "  WITH:    $pass_with/$total_assertions assertions, $words_with words, ${duration_with}ms"
}

# Clear previous results
rm -f "$RESULTS_DIR/ab-summary.csv"
echo "name|without_pass|with_pass|without_words|with_words|without_time|with_time" > "$RESULTS_DIR/ab-summary.csv"

if [ "${1:-all}" = "all" ]; then
  for i in $(seq 0 $((EVAL_COUNT - 1))); do
    run_eval "$i"
  done
else
  run_eval "$1"
fi

echo ""
echo "=== A/B Summary ==="
column -t -s'|' "$RESULTS_DIR/ab-summary.csv"
