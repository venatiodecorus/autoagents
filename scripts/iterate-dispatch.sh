#!/usr/bin/env bash
# scripts/iterate-dispatch.sh
#
# Step 1 of /iterate: read repo state and decide which workflow should run.
# Side-effect-free: reads files and GitHub state, but never changes git or issues.

set -euo pipefail

cd "$(dirname "$0")/.."

PARALLEL_BUILDERS="${PARALLEL_BUILDERS:-2}"
if ! [[ "$PARALLEL_BUILDERS" =~ ^[1-9][0-9]*$ ]]; then
  PARALLEL_BUILDERS=2
fi

ITER_NUM=$(find .llm -maxdepth 1 -name 'iter-*.md' 2>/dev/null | wc -l | tr -d ' ')
ITER_NUM=$((ITER_NUM + 1))
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ ! -f SPEC.md ]; then
  MODE=planner
  REASON="SPEC.md does not exist; planner bootstraps from BRIEF.md and supplementary docs"
  OPEN_ISSUES=0
  BUILDER_COUNT=0
else
  OPEN_ISSUES=$(gh issue list --state open --limit 200 --json number,labels --jq 'map(select(.labels | any(.name == "blocked") | not)) | length')
  if [ "$OPEN_ISSUES" -gt 0 ]; then
    MODE=builder
    if [ "$OPEN_ISSUES" -lt "$PARALLEL_BUILDERS" ]; then
      BUILDER_COUNT="$OPEN_ISSUES"
    else
      BUILDER_COUNT="$PARALLEL_BUILDERS"
    fi
    REASON="$OPEN_ISSUES open unblocked issue(s); dispatching $BUILDER_COUNT builder(s)"
  else
    MODE=playtester
    REASON="no open unblocked issues; playtester explores the app"
    BUILDER_COUNT=0
  fi
fi

printf 'ITER_NUM=%s\nTIMESTAMP=%s\nMODE=%s\nREASON=%s\nOPEN_ISSUES=%s\nPARALLEL_BUILDERS=%s\nBUILDER_COUNT=%s\n' \
  "$ITER_NUM" "$TIMESTAMP" "$MODE" "$REASON" "$OPEN_ISSUES" "$PARALLEL_BUILDERS" "$BUILDER_COUNT"

if [ "${MODE:-}" = "builder" ]; then
  echo "---"
  gh issue list --state open --limit 200 --json number,title,labels --jq '
    map(select(.labels | any(.name == "blocked") | not))
    | sort_by(
        (if   any(.labels[]; .name == "priority/high")   then 0
         elif any(.labels[]; .name == "priority/medium") then 1
         elif any(.labels[]; .name == "priority/low")    then 2
         else 3 end),
        .number
      )
    | .[]
    | "ISSUE=\(.number)\tTITLE=\(.title)"
  '
fi
