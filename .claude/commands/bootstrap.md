---
description: One-time setup for the autoagents loop: git, GitHub repo, labels, and baseline checks.
allowed-tools: Bash(git:*), Bash(gh:*), Bash(node:*), Bash(npm:*), Bash(test:*), Bash(mkdir:*), Read, Write, Edit
---

One-time bootstrap. Keep it idempotent; skip steps that are already complete.

## Step 1: Prerequisites

```bash
gh auth status || { echo "Run 'gh auth login' first"; exit 1; }
test -f BRIEF.md || { echo "Create BRIEF.md with your app pitch first"; exit 1; }
```

If `BRIEF.md` still contains only placeholder text, warn the user but continue. They may want to initialize infrastructure before writing the final pitch.

## Step 2: Initialize Git

```bash
if [ ! -d .git ]; then
  git init -b main
  git add .
  git commit -m "chore: initial autoagents scaffold"
fi
```

## Step 3: Create Private GitHub Repo

Use the current directory name as the default repo name unless the user provides a different one.

```bash
REPO_NAME=$(basename "$PWD")
if ! gh repo view 2>/dev/null; then
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
fi
```

If a remote repo already exists but `origin` is missing, add it from `gh repo view` and push `main`.

## Step 4: Create Labels

Create or update these labels with `gh label create <name> --color <hex> --description <desc> --force`:

| Name | Color | Description |
| --- | --- | --- |
| `bug` | `d73a4a` | Something is broken |
| `enhancement` | `a2eeef` | New feature or improvement |
| `chore` | `cfd3d7` | Infra, docs, tests, or housekeeping |
| `priority/high` | `b60205` | Blocks core progress or severe defect |
| `priority/medium` | `fbca04` | Important but not blocking |
| `priority/low` | `0e8a16` | Nice to have |
| `blocked` | `000000` | Agent could not proceed without follow-up |
| `agent/planner` | `1d76db` | Filed by planner |
| `agent/builder` | `5319e7` | Filed by builder |
| `agent/playtester` | `c5def5` | Filed by playtester |

## Step 5: Prepare App Scaffold

If `app/` already exists, do not overwrite it. If the brief clearly names a stack and the scaffold is trivial, create the smallest runnable app skeleton under `app/`; otherwise leave app creation to the planner's first issues.

If `scripts/gates.sh` exists, run it. Otherwise run only safe baseline checks that match existing files, such as `npm install` and package scripts inside `app/` when `app/package.json` exists.

## Step 6: Commit And Push

```bash
git add -A
git diff --cached --quiet || git commit -m "chore: bootstrap autoagents project"
git push -u origin main
```

## Step 7: Report

Print:

```text
Bootstrap complete.
Repo: <owner>/<repo>
Next: fill in BRIEF.md if needed, then run /loop /iterate
```
