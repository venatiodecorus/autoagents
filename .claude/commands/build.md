---
description: Force one builder run, then merge and close serially if it succeeds.
allowed-tools: Task, Bash(gh:*), Bash(git:*), Bash(date:*), Bash(test:*), Read, Write
argument-hint: [issue-number]
---

Force-run the builder for one issue.

1. If `$ARGUMENTS` contains an issue number, use it. Otherwise choose the top open unblocked issue with the same priority order as `/iterate`: `priority/high`, `priority/medium`, `priority/low`, unlabeled; oldest issue number first.
2. Read the issue title and derive branch `iter/<N>-<slug>` and worktree `.worktrees/iter-<N>-<slug>`.
3. Spawn the `builder` subagent with this prompt:

```text
Run a builder iteration per your agent definition in branch-only mode.
Issue number: <N>
Issue title: <TITLE>
Worktree path: .worktrees/iter-<N>-<slug>
Branch: iter/<N>-<slug>

Create or reuse that worktree, work only inside it, run quality gates, commit, and push the feature branch. Do not merge to main, push main, or close the issue. Return: issue number, branch, worktree, status pushed|blocked|failed, head SHA if pushed, and summary.
```

4. If the builder returns `status pushed`, merge from the main working tree:

```bash
git checkout main
git pull --rebase origin main
git -C .worktrees/iter-<N>-<slug> rebase main
git merge --ff-only iter/<N>-<slug>
git push origin main
SHA=$(git rev-parse HEAD)
gh issue close <N> --comment "Shipped in $SHA via iter/<N>-<slug>. Builder summary: <summary>."
```

5. If merge fails, leave the issue open and comment with the blocker. Do not force push and do not close the issue.
6. Append an iteration log entry under `.llm/` with `agent: builder` and `reason: manual /build invocation`.
7. Report a one-line summary: issue, branch, merged/blocked/failed, commit SHA if merged.
