# 2026-06-20 — Debian package for Ubuntu

## Added
- `scripts/deb/` — source files for building a `.deb` package that replicates
  `scripts/install.sh` via `apt install ./claude-docker_*.deb`:
  - `build-deb.sh` — assembles staging tree, substitutes version from
    `package.json`, calls `dpkg-deb --build`. Output: `dist/claude-docker_<version>_all.deb`.
    Takes `launcher`, `docker-compose.yml`, `.env.example` directly from the
    repo root.
  - `control` — package metadata (`Architecture: all`, `Depends: curl`).
  - `postinst` — installs Docker if absent, adds user to `docker` group,
    copies files to `~/claude-docker/`, creates `.env`, pulls the Docker image,
    runs `launcher --install`.
  - `postrm` — on `purge` prints a notice; `~/claude-docker` and the Docker
    image are intentionally left in place.
