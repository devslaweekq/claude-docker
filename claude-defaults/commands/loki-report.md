---
description: Query Grafana Loki AppExceptionFilter logs, group by service/endpoint/error, write report to file
argument-hint: [cluster] [filter] [time-range] [output-file]
---

Query Grafana Loki logs and produce a structured exception report.

**Step 1 — Resolve parameters from $ARGUMENTS.**

Parse $ARGUMENTS using both key=value syntax and natural language. Extract:

- **Cluster** — key `cluster=<value>` OR any word matching a known cluster name (e.g. `ru-prod`, `eu-prod`, `staging`). Default: `ru-prod`
- **Log filter** — key `filter=<value>` OR any word/phrase that looks like a class/filter name (PascalCase token, e.g. `PaymentService`,
  `AppExceptionFilter`). Default: `AppExceptionFilter`
- **Time range** — key `time=<value>` OR natural phrases like "2 hours", "30 minutes", "last 3h". Default: `30m`
- **Output file** — key `file=<value>`. Default: `release-<today-DD.MM>.md`

Examples of valid $ARGUMENTS:

- `cluster=eu-prod filter=PaymentService time=2h`
- `ru-prod last 2 hours PaymentService`
- `staging AppExceptionFilter 30m`

---

Parallelize this task by dispatching 4 independent agents concurrently (all 4 in a single turn). Use the dispatching-parallel-agents skill.

**Agent 1 — Service distribution:** Query Loki: `{cluster="<cluster>"} |= "<filter>"` for the resolved time range. Discover the correct
cluster label via `mcp__grafana__list_loki_label_names` / `mcp__grafana__list_loki_label_values`. Count exceptions per `service_name` label.
Return: service → count table, total, cluster label used, sample log line.

**Agent 2 — Endpoint analysis:** Same Loki query. Extract HTTP method + path from log JSON fields (`path`, `url`, `originalUrl`, `route`).
Count per unique endpoint. Return: endpoint → count table, top endpoint, total unique endpoints, note on log structure.

**Agent 3 — Error types & HTTP status codes:** Same Loki query. Extract `statusCode`, exception class name (`name` field), and `message`.
Return: HTTP status distribution, exception type distribution, top-10 error messages with counts.

**Agent 4 — Timeline & rate:** Same Loki query. Use `mcp__grafana__query_loki_stats` and/or `count_over_time` in windows of 1/10 of the
total time range to get time distribution. Return: total count, avg rate/min, peak window, quiet window, trend
(increasing/decreasing/stable), distribution table.

---

After all 4 agents complete, synthesize their results into a Markdown report and write it to the output file. The report must include:

1. Header with cluster, time range, filter, total count
2. Exceptions by service (table with count + %)
3. Exceptions by endpoint (table)
4. HTTP status codes distribution (table)
5. Error types distribution (table)
6. Top error messages
7. Timeline & rate (table + trend)
8. Key observations (high/medium/low priority findings)

$ARGUMENTS
