---
description: Force a planner run to create or refine SPEC.md, PLAN.md, and backlog.
allowed-tools: Task, Bash(gh:*), Bash(git:*), Bash(date:*), Read, Write
---

Force-run the planner regardless of dispatcher state.

1. Spawn the `planner` subagent with: `Run a planner iteration per your agent definition. This is a manual /plan invocation by the user.`
2. After it finishes, append an iteration log entry under `.llm/` with `agent: planner` and `reason: manual /plan invocation`.
3. Report what changed: spec updates, roadmap updates, issues created, issues reprioritized, or no-op.
