# Changelog

## [1.4.12] - 2026-07-22

### Changed

- **Merged the two `apt-get` `RUN` steps in `Dockerfile` into one.** The first pass
  installed base tools (`git`, `curl`, `gnupg`, DB clients, …) without cleaning
  `/var/lib/apt/lists`; the second pass re-ran `apt-get update` to pick up the
  newly-added GitHub CLI repo, installed `gh`, and only then cleaned the lists.
  Docker layers are immutable diffs, so that cleanup — living in a separate, later
  `RUN` — never reclaimed the space from the first layer; it only hid the files via
  a whiteout in the merged view (`du` inside a running container reads 0, but the
  image's stored/pulled size still carries the first layer's package index). Both
  passes now share one `RUN`, with `rm -rf /var/lib/apt/lists/*` at the very end —
  same two `apt-get update` calls (the second still needs to see the new repo), one
  cleanup, one layer.
- **Dropped `ruby` from the base image.** Not referenced anywhere in this repo's
  scripts, docs, or Dockerfile comments — leftover weight with no in-repo consumer.
