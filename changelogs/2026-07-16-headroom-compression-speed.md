# Changelog

## [1.4.7] - 2026-07-16

### Changed

- Headroom's `environment:` block (in both `docker-compose.dev.yml` and the installed-layout
  `docker-compose.yml`) now sets five compression speed-tuning flags:
  `HEADROOM_BACKGROUND_COMPRESSION=true`, `HEADROOM_TEXT_CRUSHER=true`,
  `HEADROOM_COMPRESSION_DEADLINE_MS=150`, `HEADROOM_KOMPRESS_MAX_TOKENS=50000`, and
  `HEADROOM_COLD_START_FAST_PASS_TIMEOUT_SECONDS=5`. Together these forward requests
  uncompressed and compress in the background, fall back to a fast deterministic
  compressor instead of the ModernBERT model, and bound worst-case compression/cold-start
  stalls — cutting proxy latency for the single-session interactive `--headroom` setup.
  These flags are documented only in headroom's `CHANGELOG.md` (unreleased section), not
  the stable config docs, so revisit them if a future headroom release changes their
  behavior or defaults. Chosen as sensible defaults for an interactive session, not
  benchmarked against specific hardware.
