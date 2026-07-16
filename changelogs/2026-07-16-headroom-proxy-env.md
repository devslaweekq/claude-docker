# Changelog

## [1.4.5] - 2026-07-16

### Fixed

- Headroom container now receives `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` from `.env`, so its own upstream
  requests to the LLM API go through the configured proxy instead of the host's direct egress IP. Fixes
  `unsupported_country_region_territory` errors when accessing `http://localhost:8787` from a region the
  provider blocks directly.
