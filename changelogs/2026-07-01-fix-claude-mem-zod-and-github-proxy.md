# Changelog

## [1.3.10] - 2026-07-01

### Fixed

### `claude-mem` plugin — stop-hook error `Cannot find module 'zod/v3'`
`claude-mem@13.9.1` declares `zod@^4.4.3` as a dependency but does not bundle
it in its own `node_modules`. If the system only has `zod@3.x` available (as in
this Docker image), the plugin's worker script crashes on startup with
`Cannot find module 'zod/v3'` — because the `zod/v3` subpath export was
introduced in zod v4.

`menu.sh` now checks at every container startup whether `zod` is present in the
installed `claude-mem` plugin directory. If it is missing, it runs:
```
npm install zod@'^4.4.3' --no-save --ignore-scripts
```
`--ignore-scripts` prevents a native rebuild of `tree-sitter` (which has no
build toolchain in the image) from blocking the install.

### `.env.example` — extended GitHub URLs in `NO_PROXY`
Added missing GitHub service hosts to the default bypass list so they are never
routed through a corporate proxy:

| Host                      | Purpose         |
| ------------------------- | --------------- |
| `*.githubusercontent.com` | Git LFS objects |
| `*.github.com`            | GitHub pages    |
| `github.com`              | GitHub pages    |
