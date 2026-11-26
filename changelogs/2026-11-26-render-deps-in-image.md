# Changelog

## [1.5.0] - 2026-11-26

### Added

#### Rendering dependencies in the image

- The image now ships `ffmpeg`, fonts (`fonts-liberation`, `fonts-noto-color-emoji`, `fonts-dejavu-core`) and the
  shared libraries headless Chromium needs (`libnss3`, `libnspr4`, `libgbm1`, `libdbus-1-3`, `libxkbcommon0`,
  `libxcomposite1`, `libxdamage1`, `libxfixes3`, `libxrandr2`, `libxrender1`, `libxi6`, `libdrm2`, `libpango-1.0-0`,
  `libcairo2`, `libx11-6`, `libxext6`, `libxcb1`, plus `libasound2`, `libatk1.0-0`, `libatk-bridge2.0-0`,
  `libatspi2.0-0`, `libglib2.0-0`, `libcups2`).
- Before this, Chromium from `~/.cache/ms-playwright` exited with code 127 inside the container (missing shared
  libraries) and there was no `ffmpeg`, so an agent session could not render images or video (Playwright,
  HyperFrames, Remotion) and the work had to be done on the host.
- The browser itself is not baked in: the Playwright Chromium already present in the mounted home is reused.
- Packages renamed to `*t64` on newer Debian/Ubuntu are resolved by a small loop in the Dockerfile
  (`libasound2t64` or `libasound2`, etc.), so the same Dockerfile builds on both naming schemes.

### Changed

- The image is larger because of `ffmpeg`, fonts and the X/GL libraries. Re-pull or rebuild the image to get them.
