# Agent instructions for claude-docker

The full project rules live in [`.claude/CLAUDE.md`](.claude/CLAUDE.md). Read it before changing anything,
**regardless of the directory the session was started in** (a session started outside this repo does not
load it automatically). This file is the entry point for any agent; the essentials are repeated below.

## Release checklist — run it every time, before finishing a turn with changes in the working tree

Anything that changes what ships to users (`claude-docker/launcher`, `docker-compose.yml`, `.env.example`,
`package.json`, `scripts/**`, `claude-docker/claude-defaults/**`, the Dockerfile) reaches clients **only** through a
new `.deb`/image, and the release workflows (`.github/workflows/deb-release.yml`, `docker-publish.yml`) build
it from the version in `package.json`. No version bump = no update for clients.

1. **Check git state first**: `git status`, `git log --oneline -5`, `git log --oneline origin/main..HEAD`.
2. **Bump once per commit batch.**
   - No unpushed commits and no bump in the working tree yet → run `npm run bump <version> <slug>`
     (never edit versions by hand; it updates `package.json`, `package-lock.json`, `launcher`
     and creates `changelogs/<date>-<slug>.md`).
   - A bump for this batch already exists (unpushed commits, or `package.json` version already differs from
     `origin/main`) → **do not bump again**; only extend the existing changelog file.
3. **Write or update the changelog** in `changelogs/` (English, Keep a Changelog categories, see
   `changelogs/README.md`). Every change in the batch must be reflected in it.
4. **Mirror linked files**: `scripts/install.sh` and `scripts/deb/postinst` are edited in parallel.
5. **Never commit or push.** Finish with a one-line commit message (conventional commits, ≤ 100 chars,
   English) as plain text.

Re-verify this checklist on every turn that touches files, not only the first one.
