# Changelog

## [1.3.11] - 2026-07-09

### Changed

### `comfyui/Dockerfile` — use `uv pip` instead of `pip3`
Replaced `pip3 install --break-system-packages` with `uv pip install --system
--break-system-packages`, reusing the `uv` binary already copied from
`ghcr.io/astral-sh/uv:latest` in the main image build. `uv` resolves and
installs packages significantly faster than `pip`, speeding up the
torch/torchvision/torchaudio and ComfyUI `requirements.txt` install layers.

`python3-pip` was dropped from the `apt-get install` list since it is no
longer needed.

`uv` still enforces the PEP 668 "externally managed environment" marker like
`pip` does, so `--break-system-packages` is required alongside `--system` to
install into the system Python inside the container.
