# VS Code / Cursor extension for claude-docker — work plan for agents

Status: **draft plan, not yet approved as a design.** Items marked _(assumption)_ are the author's proposals, not
decisions made by the project owner — confirm or correct them before building on them.

## 1. Goal

A standalone VS Code / Cursor extension that gives the owner everything `claude-docker/launcher` gives in a terminal,
but from native editor UI: a sidebar to pick projects and sessions, buttons to start/stop optional services, and
Claude Code sessions opened in editor terminals.

Decided by the owner:

- The extension is a **separate project**. It does **not** modify this repository (`launcher`, `menu.sh`, compose files, image).
- It runs **the same Docker image** (`slaweekq/claude-docker`), so `claude` still runs inside the isolated container,
  authenticated with the same OAuth token (`CLAUDE_CODE_OAUTH_TOKEN`).
- All launcher functionality is reimplemented inside the extension (TypeScript, `docker` CLI under the hood).

Non-goals:

- No custom chat UI / webview that re-implements Claude Code's conversation, diffs or permission prompts. Sessions are
  the real `claude` TUI in an editor terminal.
- No changes to the Docker image, `docker-compose*.yml`, or `launcher`.
- No Windows-specific work in the first iteration _(assumption)_.

Anti-goal: anything that weakens isolation (e.g. running `claude` on the host, or mounting more than `PROJECT_DIRS`).

## 2. What the launcher does today (to be reimplemented)

Source of truth: `claude-docker/launcher`, `docker-compose.yml`, `claude-docker/scripts/builds/{menu.sh,sessions.js}`,
`.env.example`, `claude-docker/claude-defaults/`.

| Capability                   | Today                                                                                                                                    | Extension equivalent                                         |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Start a session              | `docker compose run --rm` with host network, `user 0:0`, `-v ${CLAUDE_HOME}:/home/node`, `-v <project>:/workspace/<name>`, `.env` as env | `docker run` assembled in TS, started in a VS Code terminal  |
| Project discovery            | `PROJECT_DIRS` roots; each subdir is a project; cwd-aware smart launch                                                                   | Tree view of projects; workspace folder is preselected       |
| Session list / resume        | `sessions.js` reads `~/.claude/projects/<encoded cwd>/<id>.jsonl` (encoding: `/`, `_`, `.` → `-`)                                        | Read the same files on the host from the shared home dir     |
| MCP servers on/off           | `menu.sh` edits `mcpServers` in `~/.claude.json` against shipped `claude-defaults/mcp.json`                                              | TS port of the same merge/toggle logic, with a checkbox list |
| Defaults seeding             | `claude-defaults/{CLAUDE.md,settings.json,mcp.json}` seeded into home once                                                               | Bundle the defaults in the extension; seed on first run      |
| Optional services            | `--comfyui` (GPU, :8188), `--headroom` (proxy, :8787) via compose profiles, stopped on exit, ref-counted across sessions                 | Toggle buttons; same containers/labels; ref-count by label   |
| Host Playwright MCP          | Launcher starts a host-side server (node + Chrome), `--no-playwright` to skip                                                            | Same, optional, off by default _(assumption)_                |
| Proxy / TLS CA               | `HTTP_PROXY`, `HTTPS_PROXY`, `NODE_EXTRA_CA_CERTS`, `./certs` mounted read-only                                                          | Settings + pass-through to the container                     |
| Image pull / update          | `--pull`, `--build` (maintainers only)                                                                                                   | "Pull latest image" command; `--build` out of scope          |
| Passthrough (`claude login`) | Any non-flag args run `claude <args>` in a throwaway container                                                                           | Commands: "Login", "Setup token", "Auth status"              |

## 3. Decisions made by the plan author (_assumptions_ — please confirm)

1. **Own config, shared data.** The extension keeps its own settings (VS Code `settings.json` + `SecretStorage` for the
   token) and does **not** read `.env` files. The Claude home dir defaults to `~/claude-docker/home`, the same one the
   launcher uses, so sessions and credentials are shared. It is a setting, so it can point elsewhere.
2. **Token storage.** `CLAUDE_CODE_OAUTH_TOKEN` and other secrets (GH, Jira, Grafana, Outline, ...) live in VS Code
   `SecretStorage`, injected into the container via `-e VAR` (name only on the command line, value via the process
   environment) so they never appear in `docker inspect` args or logs.
3. **Sessions are editor terminals** running `docker run -it ...` — not a webview.
4. **Language/tooling:** TypeScript, `esbuild`, `@vscode/test-electron`, `vsce` + `ovsx` for packaging. Targets VS Code
   and Cursor (Cursor installs `.vsix` / Open VSX).
5. **Location:** a new repository, e.g. `claude-docker-vscode`. Not inside this monorepo.
6. Docker is invoked through the `docker` CLI (not the Docker Engine API) to match the launcher's behaviour exactly
   and to keep the extension dependency-free.

## 4. Architecture sketch

```
src/
  extension.ts            activation, command registration
  config/                 settings schema, SecretStorage wrapper, defaults
  docker/
    cli.ts                spawn docker, parse output, error mapping
    runSession.ts         build the `docker run` argv (mounts, env, network, user, labels)
    services.ts           comfyui / headroom start/stop, label-based ref counting
    image.ts              pull, version check
  projects/discovery.ts   PROJECT_DIRS roots -> projects, path <-> /workspace mapping
  sessions/
    encode.ts             cwd -> ~/.claude/projects dir name (port of sessions.js)
    reader.ts             list sessions, first prompt, mtime, size (read-only)
  mcp/
    catalog.ts            bundled claude-defaults/mcp.json
    state.ts              read/write mcpServers in ~/.claude.json (port of menu.sh logic)
  ui/
    projectsView.ts       TreeView: projects -> sessions
    servicesView.ts       ComfyUI / Headroom / Playwright toggles + status
    mcpView.ts            QuickPick / TreeView with checkboxes
    statusBar.ts          Docker state, active sessions, version
  terminal/launch.ts      createTerminal + sendText / shellPath+args
resources/claude-defaults/  copied snapshot of this repo's claude-defaults (see risk R2)
```

## 5. Work packages

Each package is self-contained, has acceptance criteria, and can be handed to one agent. Packages in the same
"wave" have no dependencies on each other.

### Wave 0 — foundation (sequential, one agent)

**WP0. Project scaffold.** New repo; `package.json` with `engines.vscode`, activation events, contributes skeleton;
esbuild bundling; ESLint/Prettier; a CI workflow (lint, typecheck, unit tests, `vsce package`); README stub.
Check the latest GitHub Actions versions via `mcp__github__get_latest_release` before writing the workflow (project rule).
_Accept:_ `F5` launches an Extension Development Host; `npm test` runs an empty suite; `vsce package` produces a `.vsix`.

### Wave 1 — independent building blocks (parallel)

**WP1. Docker CLI layer + session launch.** `docker/cli.ts`, `docker/runSession.ts`, `terminal/launch.ts`. Build the
exact argv the compose file implies (host network, root user, home + project mounts, env, labels
`claude-docker.role=session`, `--rm`, tty). Detect missing Docker / permission problems with actionable errors.
_Accept:_ a command "Start session in project X" opens a terminal with a working `claude` using the shared home dir.
Unit tests assert the argv against golden fixtures derived from `docker compose config` output of this repo.

**WP2. Settings and secrets.** Settings schema (projects roots, Claude home, image tag, proxy, extra mounts), a
"Set token" flow writing to `SecretStorage`, env injection helper that never puts secret values in argv.
_Accept:_ no secret appears in `docker inspect`, process args, or the Output channel; unit-tested.

**WP3. Project discovery.** `PROJECT_DIRS` semantics from the README ("Smart launch from any folder" table): project
inside a root, root itself, or outside all roots (cwd mounted as scratch). Host path ↔ `/workspace/<name>` mapping.
_Accept:_ table-driven tests for all three cases plus symlinks and name collisions.

**WP4. Session reader.** Port `sessions.js`: path encoding, listing `<id>.jsonl`, first user prompt, relative time,
size; read-only, tolerant to corrupt/partial files. _Accept:_ output matches `sessions.js` on a shared fixture corpus
(the plan author recommends a cross-check test that runs the original script against the same fixtures).

**WP5. MCP state.** Port the `mcpServers` merge/toggle logic from `menu.sh` (including the Playwright special case and
the "connected servers" detection) against the bundled `mcp.json`. _Accept:_ same resulting `~/.claude.json` as
`menu.sh` for a set of fixture inputs; never deletes unknown user entries; atomic write with backup.

### Wave 2 — features on top of the blocks (parallel)

**WP6. Projects/sessions tree view** (needs WP3, WP4). Projects → sessions; actions: new session, resume
(`claude --resume <id>`), open scratch, open bash. _Accept:_ resume opens the right session; empty and error states handled.

**WP7. Optional services** (needs WP1, WP2). ComfyUI and Headroom start/stop with status polling, label-based
ref counting so closing one session does not stop a service another session uses (mirror `_svc_register` /
`_svc_in_use` in `launcher`), Headroom routing env for sessions. _Accept:_ two concurrent sessions, closing one keeps the
service up; closing the last stops it; GPU absence produces a clear message.

**WP8. MCP view** (needs WP5). Checkbox UI over the catalog showing connected vs available servers, with a note
about which env vars each server needs. _Accept:_ toggling matches `menu.sh` behaviour; missing-credentials warning.

**WP9. Passthrough commands** (needs WP1). "Login", "Setup token" (stores the result into `SecretStorage` on user
confirmation), "Auth status", "Pull latest image", "Show version". _Accept:_ each runs in a throwaway container and
reports the exit code.

### Wave 3 — polish (parallel, after Wave 2)

**WP10. Host Playwright MCP** (optional). Start/stop the host-side server the way the launcher does, skip when
Node/Chrome are missing, honour the AppArmor `--no-sandbox` case. Off by default.

**WP11. Status bar, onboarding walkthrough, docs.** First-run checks (Docker present, image pulled, token set,
defaults seeded), `walkthrough` contribution, README with screenshots.

**WP12. Packaging and release.** `.vsix` build, Open VSX publish for Cursor, optional Marketplace publish, versioning
and changelog scheme in the new repo.

## 6. Cross-cutting rules for every agent

- English only in files, comments, commit messages and docs.
- Never read or print real `.env` files or tokens; use `.env.example` and fixtures.
- Do not run scripts, builds or Docker commands against the owner's real environment without asking; tests must run
  against fixtures and a mocked `docker` binary.
- Do not commit or push; hand back a one-line commit message (<= 100 chars).
- Keep commented-out lines that already exist in ported files unless told otherwise.
- Where the source launcher is silent or ambiguous, say so in the PR/summary instead of inventing behaviour.

## 7. Risks and open questions

- **R1 Docker access from the extension host.** Remote/SSH/Dev Container windows run the extension on another
  machine; the extension should declare `extensionKind: ["ui"]` so it runs where Docker and the home dir are.
- **R2 Drift from the launcher.** `claude-defaults/` and the `menu.sh` MCP logic are ported by copy. A sync check
  (script comparing the bundled snapshot with a given checkout of this repo) is proposed, not mandatory.
- **R3 Session file format.** `~/.claude/projects/...jsonl` is an internal Claude Code format; the reader must degrade
  gracefully if it changes.
- **R4 Root in container.** The launcher runs as `user 0:0`; files created in mounted projects are root-owned on the
  host. The extension should keep parity with the launcher first, and treat any change as a separate decision.
- **R5 Cursor compatibility.** Verify the terminal/tree-view/SecretStorage APIs used exist in the Cursor fork's
  VS Code base version; pin `engines.vscode` accordingly.
- **Open:** should the extension also support the "Docker image only" install (no clone, no `~/claude-docker`)?
  The plan assumes yes, because it never reads the launcher or compose file.
- **Open:** is a native chat UI (e.g. wrapping the official Claude Code extension via a process wrapper) wanted later?
  Out of scope here; revisit after Wave 3.
