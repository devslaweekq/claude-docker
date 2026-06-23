# Changelog

## [1.3.3] - 2026-06-23

### Added
- Auto-configure `~/.wslconfig` on WSL2 during install: sets memory to 75% of host RAM and all logical processors so Docker Desktop gets proper resources without manual tuning
- `loki-report` command: time range, cluster, and log filter are now parsed from natural language in `$ARGUMENTS` (key=value and plain text); time range is configurable with default of 1h

### Fixed
- Uncommented `NO_PROXY` / `no_proxy` defaults in `.env.example` so proxy bypass works out of the box
