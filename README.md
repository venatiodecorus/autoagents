# autoagents

An agentic app-development loop. AI agents plan, build, and playtest an application iteratively, using GitHub issues as the shared backlog. Builder work can run in parallel safely through isolated git worktrees; final merges stay serialized.

## Quickstart

1. Edit `BRIEF.md` with a 1-3 paragraph description of the app you want.
2. Run `/bootstrap` to initialize git, create the private GitHub repo, create labels, and prepare the app scaffold.
3. Run `/loop /iterate` to let the agent loop continue until you stop it.

NOTE: I've been running these in [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/). I recommend using some form of isolation when using unattended agents.

## Loop Behavior

Each `/iterate` tick dispatches one workflow:

| State | Action |
| --- | --- |
| `SPEC.md` missing | run planner to write spec, roadmap, and seed issues |
| open unblocked issues exist | run up to `PARALLEL_BUILDERS` builders in parallel |
| no open unblocked issues | run playtester to discover and file issues |

Default builder concurrency is `2`. Override per run with:

```bash
PARALLEL_BUILDERS=3 /loop /iterate
```

Parallel builders implement separate issues in `.worktrees/iter-<issue>-<slug>` and push feature branches. The parent `/iterate` command rebases and fast-forward merges successful branches into `main` one at a time, then closes their issues.

## Manual Commands

- `/plan` runs the planner regardless of state.
- `/build [issue-number]` runs a builder for one issue, then the command performs the same serialized merge/close step as `/iterate`.
- `/playtest` runs the playtester regardless of state.

## Layout

| Path | Purpose |
| --- | --- |
| `BRIEF.md` | Human-written product pitch |
| `SPEC.md` | Authoritative product spec written by planner |
| `PLAN.md` | Phased roadmap maintained by planner |
| `CLAUDE.md` | Agent conventions and safety rules |
| `.claude/agents/` | Planner, builder, playtester definitions |
| `.claude/commands/` | Slash command workflows |
| `.llm/` | Per-iteration audit trail and playtest artifacts |
| `.worktrees/` | Ignored git worktrees for parallel builders |
| `app/` | Generated application, unless `SPEC.md` declares another directory |

## Requirements

- Claude Code or a compatible agent runner for these slash-command templates
- `gh` authenticated against your GitHub account
- Git with worktree support
- The runtime required by the app scaffold, usually Node 20+ for web apps

## Design Principle

Parallelism is only for implementation. Builders may race on independent branches, but `main` remains single-writer: the parent command serially rebases, fast-forward merges successful branches, and leaves conflicts as open follow-up issues.
