---
description: One tick of the agentic loop with parallel builders and serialized merges.
allowed-tools: Bash(./scripts/iterate-dispatch.sh:*), Bash(gh:*), Bash(git:*), Bash(date:*), Bash(test:*), Bash(mkdir:*), Read, Write, Task
---

Run one tick of the agentic loop. Decide which workflow fires, dispatch it, write an iteration log, and report the outcome.

## Step 1: Determine Mode

Run:

```bash
./scripts/iterate-dispatch.sh
```

Parse the key/value output:

```text
ITER_NUM=<n>
TIMESTAMP=<iso8601>
MODE=<planner|builder|playtester>
REASON=<short text>
OPEN_ISSUES=<count of open unblocked issues>
PARALLEL_BUILDERS=<configured limit>
BUILDER_COUNT=<number to dispatch this tick>
```

When `MODE=builder`, the `---` section contains prioritized issue rows:

```text
ISSUE=<number>	TITLE=<title>
```

Select the first `BUILDER_COUNT` rows. Do not let builders pick their own issues during `/iterate`; each builder must receive one explicit issue number.

## Step 2: Dispatch

Use the Task tool.

For `MODE=planner`, spawn one planner:

```text
Run a planner iteration per your agent definition. The dispatcher's reason: <REASON>. Read CLAUDE.md, BRIEF.md, and any existing SPEC.md/PLAN.md before acting.
```

For `MODE=playtester`, spawn one playtester:

```text
Run a playtester iteration per your agent definition. The dispatcher's reason: <REASON>. Exercise the app according to SPEC.md and file up to 5 issues for observed defects.
```

For `MODE=builder`, spawn `BUILDER_COUNT` builder agents in parallel. Each prompt must include the issue number and the expected branch/worktree names:

```text
Run a builder iteration per your agent definition in parallel-builder mode.
Issue number: <N>
Issue title: <TITLE>
Worktree path: .worktrees/iter-<N>-<slug>
Branch: iter/<N>-<slug>

Create or reuse that worktree, work only inside it, run quality gates, commit, and push the feature branch. Do not merge to main, push main, or close the issue. Return a concise result with: issue number, branch, worktree, status pushed|blocked|failed, head SHA if pushed, and summary.
```

Use a 3-5 word lowercase kebab-case slug derived from the issue title. If two selected issues would produce the same branch slug, keep the issue number prefix; that is sufficient uniqueness.

Wait for every builder to finish before merging anything.

## Step 3: Merge Builder Branches

Only for `MODE=builder`.

For each builder result with `status pushed`, integrate serially from the main working tree in the same priority order used for dispatch. Rebase the feature branch onto the latest `main` before the fast-forward merge so later parallel branches can still merge after earlier branches advance `main`:

```bash
git checkout main
git pull --rebase origin main
git -C .worktrees/iter-<N>-<slug> rebase main
git merge --ff-only iter/<N>-<slug>
git push origin main
SHA=$(git rev-parse HEAD)
gh issue close <N> --comment "Shipped in $SHA via iter/<N>-<slug>. Builder summary: <summary>."
```

If the rebase or merge fails, do not force it and do not close the issue. Abort any in-progress rebase in the issue worktree or merge in the main worktree if needed, leave the branch intact, and comment:

```bash
gh issue comment <N> --body "Parallel builder branch iter/<N>-<slug> could not be merged cleanly by /iterate. The issue remains open for follow-up. Blocker: <short error>."
```

If a builder reports `blocked`, it should already have labeled/commented the issue. Include it in the iteration log but do not merge or close it.

If a builder reports `failed` without updating the issue, add a short issue comment with the failure and leave it open.

## Step 4: Log It

Write `.llm/iter-NNN.md`, where `NNN` is the zero-padded iteration number from step 1:

```markdown
---
iteration: <N>
timestamp: <TIMESTAMP>
agent: <planner|builder|playtester>
---

## Reason for dispatch

<REASON>

## Outcome

<2-6 sentences summarizing what happened. For builder waves, list each issue, branch, status, merge SHA if merged, or blocker if not merged.>

## State after

- open unblocked issues: <resolved count>
- last commit: <resolved git log -1 --oneline, or "no commits yet">
```

Commit and push only the iteration log from the main working tree:

```bash
git add .llm/iter-NNN.md
git diff --cached --quiet || git commit -m "chore(iter): log iter NNN [<agent>] - <one-line outcome>"
git push origin main
```

If the push fails because `main` moved, run `git pull --rebase origin main` and retry once. Never force push.

## Step 5: Report

Print one line:

```text
iter <N> [<MODE>] - <one-sentence outcome>
```

## Guardrails

- If `BRIEF.md` does not exist, stop and tell the user to run `/bootstrap` first.
- If `gh auth status` fails, stop and tell the user to run `gh auth login`.
- Parent `/iterate` owns merges to `main` for builder waves.
- Builders own implementation only; they must not close issues in `/iterate` parallel-builder mode.
- Always write the iteration log even when a subagent fails, so the next tick has context.
