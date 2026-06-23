# Changelog

## [1.3.1] - 2026-06-23

### Fixed

- **Grafana MCP**: fix `uvx` argument order — `--disable-write` was passed as a flag to `uvx` instead of `mcp-grafana`, causing the server to fail with error `-32000` on connection
- **Grafana MCP**: add `NO_PROXY=*` to `mcp-grafana` process env so it connects to Grafana directly, bypassing the system proxy (`HTTP_PROXY`) which is unreachable from inside the container

### Added

- `npm run bump` script alias for `scripts/utils/bump-version.sh`
- `CLAUDE.md` — project-level rules for Claude Code (language, git workflow, version bumping, linked files)
