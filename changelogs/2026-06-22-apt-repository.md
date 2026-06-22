# Changelog

## [1.2.7] - 2026-06-22

### Added

### APT repository — automatic updates via `apt upgrade`

Ubuntu/Debian users can now receive updates automatically via `apt upgrade` instead
of manually downloading a new `.deb` on each release.

The APT repository is hosted on GitHub Pages (`gh-pages` branch) and signed with a
GPG key. Setup is fully automated through the install script — a single command
is all that is needed:

```
curl -fsSL https://raw.githubusercontent.com/devslaweekq/claude-docker/main/scripts/install.sh | bash
```

After the initial setup, `sudo apt upgrade` picks up new releases automatically.

**`install.sh`** — instead of downloading a one-off `.deb`, the script now
configures the APT repository:

1. Adds the GPG signing key to `/usr/share/keyrings/claude-docker.gpg`
2. Writes the repository entry to `/etc/apt/sources.list.d/claude-docker.list`
3. Runs `apt-get update && apt-get install claude-docker`

**`postinst`** (`.deb` package) — the post-install hook also configures the APT
repository, so users who installed via a direct `.deb` download likewise get
automatic updates from `apt upgrade` going forward.

### GitHub Actions release workflow

On every tag push matching `v*`, a GitHub Actions workflow automatically:

1. Builds the `.deb` package
2. Uploads it to the GitHub Release for that tag
3. Publishes the package to the APT repository on the `gh-pages` branch via
   `reprepro`

This means every tagged release is immediately available both as a direct `.deb`
download and through `apt upgrade` for existing installs.
