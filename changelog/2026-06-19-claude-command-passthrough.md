# 2026-06-19 — Claude command passthrough

## Added
- **Passthrough mode in `launcher`.** Any arguments that are not the launcher's
  own reserved flags (`--install`, `--pull`, `--build`) are now forwarded
  straight to `claude` inside a throwaway container, which runs the command and
  exits with claude's status code. This makes the full claude CLI available
  natively from the host symlink:
  - `claude auth status`, `claude login`, `claude setup-token`, `claude --version`, etc.
  - Token/credentials are written to the persistent `~/.claude` home volume, so a
    subsequent session is already authenticated — no more opening a session,
    shelling into the container from a second terminal, and copying the token out.
  - Bare `claude` still opens the menu/session; `claude --pull` / `claude --build`
    keep their existing meaning. `--pull` may be combined with a passthrough
    command (e.g. `claude --pull login`).
- **`--exec` dispatch in `scripts/menu.sh`** (the in-container entrypoint):
  `--exec <args…>` runs `claude <args…>` directly, skipping the menu and the
  screen reset so output stays clean and pipeable.

## Changed
- **`launcher` no longer auto-builds when the image is missing.** A missing image
  now triggers a `pull` only; a local build happens exclusively on an explicit
  `--build`. Regular users install via `install.sh` and consume the prebuilt
  image from Docker Hub, so the implicit build path is removed.

## Notes
- TTY allocation for passthrough is automatic: a pseudo-TTY is allocated only when
  both stdin and stdout are terminals (interactive `claude login`); otherwise `-T`
  is passed so piped output is not mangled (`claude auth status | grep …`).
- Passthrough commands always run in the container's default `/workspace`; they do
  not honor the caller's working directory. `claude --resume` over passthrough
  therefore lists sessions for the workspace root — the menu remains the canonical
  resume path.
