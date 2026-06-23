# Changelog

## [1.3.2] - 2026-06-23

### Fixed

- ComfyUI Dockerfile: update base image to `nvidia/cuda:13.3.0-base-ubuntu24.04`, fix `libgl1-mesa-glx` → `libgl1` for Ubuntu 24.04, add `--break-system-packages` for pip (PEP 668)

### Changed

- Split ComfyUI CI workflow into separate Build and Push steps to prevent Docker Hub upload session timeouts on large images
- `build.sh`: add CI mode (reads `DOCKER_USERNAME` from env, no interactive prompt); add proxy build args to `build_comfyui`; move session-stop and image-removal logic here (before rebuild)
- `push.sh`: now only runs `docker push`; calls `build.sh` automatically when run locally (single command for local workflow); CI calls build/push as separate steps
- `CLAUDE.md`: add rule to never delete commented-out lines without explicit user request
