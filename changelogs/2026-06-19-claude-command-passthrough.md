# 2026-06-19 — Claude command passthrough

## Added
- **Passthrough mode in `launcher`.** Unrecognized arguments are forwarded
  directly to `claude` inside a throwaway container, which exits with claude's
  status code. Makes the full Claude CLI available from the host symlink
  (`claude auth status`, `claude login`, `claude setup-token`, etc.).
  TTY is allocated automatically — only when both stdin and stdout are
  terminals; otherwise `-T` is passed so piped output stays clean.
- **`--exec` flag in `scripts/menu.sh`.** Runs `claude <args>` directly,
  bypassing the menu and screen reset so output is pipeable.
- **Argument forwarding in `launcher.bat` (Windows).** Arguments are passed
  as positional parameters (`"$@"`) instead of being spliced into the command
  string, so quotes and spaces survive.

## Changed
- **`launcher` no longer auto-builds on missing image.** A missing image now
  triggers a pull only; `--build` is required for a local build. Regular users
  consume the prebuilt image from Docker Hub.
