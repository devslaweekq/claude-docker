# Changelog

## [1.5.1] - 2026-11-26

### Added

#### Custom endpoint authentication (base URL + API key)

- `.env` can now point Claude Code at any Anthropic-compatible API instead of using the OAuth token:
  `ANTHROPIC_BASE_URL` plus `ANTHROPIC_API_KEY` (X-Api-Key) or `ANTHROPIC_AUTH_TOKEN` (Bearer), with optional
  `ANTHROPIC_MODEL` and `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL`. The variables reach the container through the
  existing `env_file`, so the launcher and compose files are unchanged.
- `menu.sh` now skips the first-run login wizard when `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` is set, as it
  already did for `CLAUDE_CODE_OAUTH_TOKEN`.
- Documented in `.env.example`, `claude-docker/README.md` (Authentication, configuration reference, troubleshooting) and
  the post-install hints of `scripts/install.sh` and `scripts/deb/postinst`.
- Known limitation: `--headroom` overrides `ANTHROPIC_BASE_URL` with the local proxy, so it cannot be combined with a
  custom endpoint.
- The VS Code extension plan (`docs/vscode-extension-plan.md`) now includes auth profiles for the same modes.

### Removed

#### ffmpeg and its dependency tree

- `ffmpeg` is no longer installed in the image. Debian's `ffmpeg` pulls in about 180 packages (~450 MB installed:
  `libllvm15`, `libgl1-mesa-dri`, `libz3-4`, `libflite1`, `libmfx1`, x265/aom/svt-av1 codecs, SDL2, PulseAudio, ...)
  and grew the image from ~1.2 GB to ~1.9 GB in 1.5.0.
- Video rendering (HyperFrames, Remotion) therefore needs its own `ffmpeg`/`ffprobe`, for example a static binary
  placed on `PATH` or pointed to by an environment variable of the tool; it is not provided by the image.

### Changed

- The rendering libraries and fonts added in 1.5.0 stay: the shared libraries headless Chromium needs
  (`libnss3`, `libgbm1`, `libasound2`, `libatk*`, `libcups2`, ...) and `fonts-liberation`, `fonts-noto-color-emoji`,
  `fonts-dejavu-core`, about 21 MB in total. They are enough to render jpg/png/pdf from HTML with the Chromium
  already present in `~/.cache/ms-playwright`.
- Re-pull or rebuild the image to get the smaller size.
