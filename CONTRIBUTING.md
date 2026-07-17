# Priorities

- Stay simple: one launcher script, config in `.env`, no extra orchestration
  layer on top of Docker Compose.
- Isolation is the whole point — the container should stay disposable and
  not leak host state in by default. Anything that widens what's mounted or
  shared with the host needs a very good reason.
- The default path (`./claude-docker/launcher`, clone-and-go) must stay frictionless.
  Optional features (ComfyUI, Headroom, corporate proxy) are opt-in flags —
  they must never complicate or slow down the default session start.
- Three install methods (clone, install script, image-only) all need to keep
  working and stay in sync — don't fix one and silently break another.

# Agenda

claude-docker is a narrowly scoped wrapper: run Claude Code in an isolated,
disposable Docker container with persistent sessions and a fast resume menu.
It's not a general devcontainer framework. New MCP servers, flags, or
integrations are judged against that one job — if something is better
solved by the user's own `.env`/proxy setup or an unrelated tool, it
probably shouldn't live here.

# Contributing guidelines

Make sure to follow these guidelines before opening an
[issue](https://github.com/devslaweekq/claude-docker/issues/new) or a
[pull request](https://github.com/devslaweekq/claude-docker/pulls):

- Before opening an issue or a pull request, check if it already exists.
- Pull requests for dependency bumps aren't needed —
  [Dependabot](.github/dependabot.yml) handles those automatically.
- Run `npm run format` before opening a pull request; CI runs a format
  check and `npm audit` on every PR.
- If you're changing `claude-docker/Dockerfile`, `claude-docker/launcher`, or
  any `scripts/`, test all three install methods you touch (clone, install
  script, image-only) — they aren't covered by automated tests.
- If you're proposing a new feature or MCP server, check it against the
  priorities above first — isolation and a frictionless default path win
  over convenience.
