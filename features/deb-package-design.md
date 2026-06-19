# Design: `claude-docker` deb package

> Feature specification.
> Goal: package claude-docker as a `.deb` so that `apt install ./claude-docker_*.deb` installs Docker,
> places project files into a system directory, and adds the `claude` command to PATH.

## Decisions Made

| Question              | Decision                                                      |
| --------------------- | ------------------------------------------------------------- |
| Docker image delivery | `docker pull slaweekq/claude-docker:latest` (from Docker Hub) |
| State storage         | Per-user in `~/claude-docker` (code read-only in `/opt`)      |
| Docker installation   | postinst installs official `docker-ce`                        |
| First-run setup       | Manual `.env` (package provides `.env.example`)               |
| Package build         | `dpkg-deb` manually via build script                          |
| Command name in PATH  | `$HOME/.local/bin/claude` (via `launcher --install`)          |

## 1. What the Package Does

`apt install ./claude-docker_1.0.0_all.deb`:

1. **(postinst)** installs official `docker-ce` if not present; adds the current user
   to the `docker` group.
2. Places immutable code in `/opt/claude-docker/`.
3. Runs `launcher --install` → `$HOME/.local/bin/claude` (symlink to `/opt/claude-docker/launcher`).
4. **(postinst)** `docker pull slaweekq/claude-docker:latest` — pulls the image.
5. On **first run** the `claude` command creates `~/claude-docker/` with `.env.example`,
   `home/`, `certs/`, prompts the user to fill in `.env` (manual setup), then exits.

## 2. File Layout

Principle: **code read-only / state per-user**. `apt upgrade` overwrites only `/opt`;
user data in `~/claude-docker` is left untouched.

```
/opt/claude-docker/        ← owned by dpkg, read-only
├── docker-compose.yml  ← adapted for path env variables
├── launcher            ← host entry script (see §4)
└── .env.example
$HOME/.local/bin/claude ← symlink to launcher

~/claude-docker/           ← created on first run by the user
├── .env        (chmod 600)
├── home/       (history, claude config)
└── certs/      (TLS CA, optional)
```

## 3. Package Control Files (`DEBIAN/`)

- **control** — `Package: claude-docker`, `Architecture: all`,
  `Depends: docker-ce | docker.io, docker-compose-plugin | docker-ce` (with fallback),
  `Maintainer`, `Description`.
- **postinst** — installs `docker-ce` from the official repo (apt key + source),
  `usermod -aG docker`, `docker pull`. Idempotent (checks `command -v docker`).
- **prerm/postrm** — on `purge`, inform the user that `~/claude-docker` and the image
  remain (do not silently delete user data).

## 4. Launcher Adaptation (Main Code Change)

The current `launcher` computes `REPO=dirname(self)` and works with `./home`, `./certs`, `./.env`
**inside the repository**. In a package this breaks because `/opt` is read-only.

New launcher:

- `CODE_DIR=/opt/claude-docker` (compose file and build context),
- `STATE_DIR="${CLAUDE_HOME:-$HOME/claude-docker}"` (env/.env/certs/home),
- if `STATE_DIR/.env` does not exist → creates the directory, copies `.env.example`, prints
  instructions, and exits,
- runs
  `docker compose -f /opt/claude-docker/docker-compose.yml --project-directory "$STATE_DIR" run ...`
  with correct mount paths.

`docker-compose.yml` is updated so that state paths are taken from env variables
(`${CLAUDE_HOME}/home`, `${CLAUDE_HOME}/certs`) rather than relative `./`.

## 5. Build

`features/deb/build-deb.sh`:

1. Assembles the directory tree `build/claude-docker_<ver>_all/`,
2. copies files and sets permissions,
3. generates `control` with the version from `package.json`,
4. calls `dpkg-deb --root-owner-group --build`.

Output — `dist/claude-docker_<ver>_all.deb`.

## 6. Testing

- `lintian` on the finished `.deb` (if available).
- Run in a clean Ubuntu container: `apt install ./*.deb` → verify that `$HOME/.local/bin/claude`
  exists, first run creates `~/claude-docker`, postinst is idempotent on reinstall.
- Smoke: `launcher --install` / `--help` prints correct help output.

## 7. Out of Scope (YAGNI)

- Publishing to a PPA / apt repository (local `.deb` only).
- Bundling the image into `.deb` or building the image locally (pull only).
- Interactive setup wizard.
