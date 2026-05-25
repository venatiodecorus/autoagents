# autoagents - agent conventions

This repo is a template for an autonomous app-improvement loop. A human writes `BRIEF.md`; agents turn it into `SPEC.md`, maintain a GitHub issue backlog, implement issues, and test the app over repeated `/loop /iterate` ticks.

## Repo Layout

```
.claude/agents/        Agent definitions: planner, builder, playtester
.claude/commands/      Slash commands: iterate, bootstrap, plan, build, playtest
.llm/iter-NNN.md       Per-iteration audit log
.llm/playtests/iter-N/ Playtester artifacts, screenshots, and notes
.worktrees/           Temporary isolated builder worktrees, ignored by git
app/                  The generated application, created by bootstrap/planner work
BRIEF.md              Human-written product pitch
SPEC.md               Authoritative app spec, written and maintained by planner
PLAN.md               Phased implementation roadmap, maintained by planner
README.md             How to run the framework
*.md                  Other root-level markdown files are supplementary design docs
```

Framework files live at the repo root. Application code lives under `app/` unless `SPEC.md` explicitly declares a different app directory. Agents must not put application code under `.claude/`, `.llm/`, `scripts/`, or repo-root documentation.

## The Loop

`/loop /iterate` runs `/iterate` indefinitely. Each tick dispatches based on state:

| Condition | Agent |
| --- | --- |
| `SPEC.md` does not exist | planner |
| open unblocked GitHub issues exist | builder wave |
| no open unblocked issues | playtester |

Builder ticks may dispatch up to `PARALLEL_BUILDERS` isolated builder agents. Default concurrency is `2`. Each builder gets one explicit issue number and a unique git worktree under `.worktrees/`.

## Parallel Builder Contract

- Builders never share the main working tree.
- Each builder creates or reuses `.worktrees/iter-<issue>-<slug>` on branch `iter/<issue>-<slug>`.
- Builders work only inside their assigned worktree and only on their assigned issue.
- Builders run the quality gates before committing.
- Builders push only their feature branch. They do not merge to `main`, push `main`, or close the issue when running from `/iterate`.
- The parent `/iterate` command waits for all builders, then serially rebases each successful branch onto current `main`, fast-forward merges it, and closes the matching issue.
- If a branch cannot merge cleanly, `/iterate` leaves the issue open and comments with the blocker.

## GitHub Conventions

- Repo is private. Origin is the GitHub remote created by `/bootstrap`.
- All implementation work is tracked as GitHub issues. Agents talk to GitHub via `gh` CLI.
- Labels created by `/bootstrap`:
  - kind: `bug`, `enhancement`, `chore`
  - priority: `priority/high`, `priority/medium`, `priority/low`
  - agent: `agent/planner`, `agent/builder`, `agent/playtester`
  - status: `blocked`
- Builders receive issues in this order: `priority/high`, `priority/medium`, `priority/low`, unlabeled. Within a priority, oldest first. `blocked` issues are skipped.
- Branch names use `iter/<issue-number>-<slug>`.
- All builder commits include `Fixes #N` so the eventual merge records the relationship.

## Quality Gates

Builders must pass the project gates before pushing a feature branch. Prefer `scripts/gates.sh` when present:

```bash
./scripts/gates.sh
```

If there is no gate script, run the commands documented in `SPEC.md`, `PLAN.md`, or `app/package.json` such as typecheck, test, and build. If gates fail, the builder may attempt one fix, rerun, and then mark the issue `blocked` if still failing.

## Playtest Target

The playtester follows `SPEC.md` and project documentation to start and exercise the app. If the app exposes a browser UI, the playtester should use Playwright or browser automation. If it is a CLI, API, library, or other app type, the playtester should run the closest realistic smoke scenario and file issues for observed defects.

## Hard Rules

- Do not bypass hooks with `--no-verify`.
- Do not use `git push --force` on `main` or feature branches.
- Do not delete `.llm/` entries; they are the audit trail.
- Do not delete `.worktrees/` directories while a builder wave is running.
- Planner never edits application code.
- Playtester never edits application code or framework files.
- Builders never edit planner/playtester definitions, slash commands, root docs, or issue workflow files unless their assigned issue explicitly asks for framework changes.
- Do not close issues without either implementing them or doing an explicit deduplication/deferral action documented in an issue comment.
