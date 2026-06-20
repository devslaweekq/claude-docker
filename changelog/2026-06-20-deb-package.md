# 2026-06-20 — deb package for Ubuntu

## Added
- `features/deb/` — files needed to build a `.deb` that replicates what
  `scripts/install.sh` does, delivered via `apt install ./claude-docker_*.deb`.

  **Result after install — identical to install.sh:**
  ```
  ~/claude-docker/
  ├── launcher            (chmod 755)
  ├── docker-compose.yml  (chmod 644)
  ├── .env.example        (chmod 644)
  ├── .env                (chmod 600, created from .env.example if absent)
  ├── home/scratch/
  └── certs/
  ~/.local/bin/claude -> ~/claude-docker/launcher
  ```

  - **`build-deb.sh`** — assembles the staging tree, substitutes version from
    `package.json`, calls `dpkg-deb --root-owner-group --build`.
    Output: `dist/claude-docker_<version>_all.deb`.
    Copies `launcher`, `docker-compose.yml`, `.env.example` directly from the
    repo root — no duplication. Run: `bash scripts/deb/build-deb.sh`.

  - **`DEBIAN/control`** — package metadata (`Architecture: all`, `Depends: curl`).

  - **`DEBIAN/postinst`** — mirrors install.sh step by step, but reads files
    from `/usr/share/claude-docker/` instead of downloading from GitHub:
    1. Installs Docker via `get.docker.com` if absent, enables the daemon.
    2. Adds `$SUDO_USER` to the `docker` group.
    3. Copies files into `~/claude-docker/`, creates `.env` if absent.
    4. Pulls `slaweekq/claude-docker:latest`.
    5. Runs `launcher --install` to add the command to PATH.
    6. Prints the same completion message as install.sh.

  - **`DEBIAN/postrm`** — on `purge` reminds the user that `~/claude-docker`
    and the Docker image are intentionally left in place.
