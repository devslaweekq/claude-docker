---
description: Fan out a task to independent parallel agents
argument-hint: <task description>
---

Parallelize this task: split it into independent parts and dispatch one agent
per part concurrently (multiple Agent calls in a single turn). Use the
dispatching-parallel-agents skill. Run at most 6 agents at once — queue the
rest. Collect and merge the results at the end.

Task: $ARGUMENTS
