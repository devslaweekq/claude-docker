# Changelog

## [1.3.7] - 2026-06-25

### Fixed

### Plugin marketplace clone fails behind corporate proxy (`Proxy CONNECT aborted`)
HTTPS marketplace clones were routed through `HTTP_PROXY`, which cannot tunnel
to GitHub. `menu.sh` now appends GitHub hosts to `NO_PROXY`/`no_proxy` at
startup and sets `git config http.https://github.com/.proxy ""`. Also seeds
GitHub ED25519 host key in `~/.ssh/known_hosts` for `/plugin marketplace add
owner/repo` SSH fallback.

### `.env.example` — GitHub in `NO_PROXY`
Default bypass list now includes `github.com`, `.github.com`, `api.github.com`,
`raw.githubusercontent.com`, `ghcr.io`.
