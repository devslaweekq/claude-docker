# Changelog

## [1.5.1] - 2026-11-26

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
