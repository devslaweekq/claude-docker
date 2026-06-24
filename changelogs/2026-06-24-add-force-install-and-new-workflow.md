# Changelog

## [1.3.4] - 2026-06-24

### Added

### `launcher --install --force` — re-run PATH setup
`--force` skips the existing-symlink shortcut so install runs again with the normal
flow: auto `claude` when the name is free, or the interactive menu when native
Claude Code is already on the system.

### `comfyui/workflows/edit.json` — img2img edit workflow (Z-Image Turbo)
New ComfyUI workflow for editing an uploaded photo: `LoadImage` → `VAEEncode` →
`KSampler` (denoise `0.30`). Positive prompt describes only the desired change;
negative prompt blocks unwanted subject/identity drift. Outputs to `edit/`.

### `comfyui/Dockerfile` — ship all bundled workflows
`COPY workflows/` replaces a single `default.json` copy so both `default.json`
and `edit.json` land in `/opt/ComfyUI/user/default/workflows/` in the image.

### Fixed

### `launcher --install` — only one PATH symlink to the launcher
Before creating or refreshing a command, remove every other `~/.local/bin/`
symlink that resolves to this launcher. Prevents duplicate commands (e.g. both
`claude` and `cladock`) after switching install names or re-running install.
