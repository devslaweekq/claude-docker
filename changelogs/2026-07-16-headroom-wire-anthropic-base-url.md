# Changelog

## [1.4.6] - 2026-07-16

### Fixed

- `launcher --headroom` now actually routes the `claude` session through the Headroom proxy. Previously it only
  started the Headroom container alongside the session — nothing pointed `claude`'s own API traffic at it, so the
  proxy sat idle and compression/caching never applied. The launcher now passes
  `-e ANTHROPIC_BASE_URL=http://localhost:8787` into the `claude` container's `docker compose run` invocation
  whenever `--headroom` is set, so the two containers (both on `network_mode: host`) actually connect.
