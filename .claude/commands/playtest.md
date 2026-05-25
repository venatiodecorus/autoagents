---
description: Force a playtester run to exercise the app and file issues.
allowed-tools: Task, Bash(gh:*), Bash(git:*), Bash(date:*), Read, Write
---

Force-run the playtester regardless of dispatcher state.

1. Spawn the `playtester` subagent with: `Run a playtester iteration per your agent definition. This is a manual /playtest invocation by the user.`
2. After it finishes, append an iteration log entry under `.llm/` with `agent: playtester` and `reason: manual /playtest invocation`.
3. Report how many issues were filed, any critical blockers, and where artifacts were written.
