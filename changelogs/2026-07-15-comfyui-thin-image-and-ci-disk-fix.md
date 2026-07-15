# Changelog

## [1.4.1] - 2026-07-15

### Changed

### `comfyui` image is now thin — torch/deps install into a mounted venv on first run
`comfyui/Dockerfile` no longer bakes `torch`/`torchvision`/`torchaudio` (cu130) or
ComfyUI's `requirements.txt` into image layers — that's multi-GB and was the reason
`comfyui-publish.yml` started failing on disk space. A new `comfyui/entrypoint.sh`
installs them into `/opt/venv` on first container start, keyed off a hash of
`requirements.txt` + the torch pin (`/opt/venv/.install-hash`) — reinstalls automatically
when either changes, otherwise reuses the existing install. ComfyUI's own code stays baked
into the image via `git clone` (small, versioned by tag).

`docker-compose.yml`/`docker-compose.dev.yml` mount `${COMFYUI_HOME}/venv:/opt/venv` —
same `~/claude-docker/comfyui/` base as `models/`, `output/`, `user/`. `scripts/install.sh`
and `scripts/deb/postinst` now create that directory on install.

First `--comfyui` launch after upgrading takes a few extra minutes while torch installs;
every launch after that is unaffected.

### `comfyui-publish.yml` — free disk space before building
`ubuntu-latest` runners ship ~30GB of preinstalled toolchains (`/usr/share/dotnet`,
`/usr/local/lib/android`, `/opt/ghc`, `/opt/hostedtoolcache`) that aren't needed for this
build. Added a cleanup step (plus `docker system prune -af`) before `docker buildx build`.

### Fixed

### `entrypoint.sh` crashed when `/opt/venv` wasn't mounted
Running the image directly (`docker run ... slaweekq/comfyui:latest`, no `-v` for
`/opt/venv`) failed with `find: '/opt/venv': No such file or directory` — the image never
created that path itself, it only ever existed via the volume mount. `Dockerfile` now
`mkdir -p /opt/venv` unconditionally, and `entrypoint.sh` does the same defensively before
touching it.
