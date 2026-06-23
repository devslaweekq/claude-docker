# Claude Code Rules for this Project

## Language

- All project files (changelogs, comments, commit messages, documentation) must be in **English only**

## Git & Releases

- **NEVER push** to `main` or any branch without explicit permission in the current user message
- **NEVER commit** — prepare everything, then give the user the commit message as plain text; committing is the user's job
- Commit message style: `feat:` / `fix:` / `chore:` conventional commits

## Workflow per Commit

Every set of changes that will land in one commit follows this exact sequence:

1. **Check current git state first** — run `git status` and `git log --oneline -5` to see what is already committed, what is staged, and what the current version is. Never assume — always verify.
2. **Make the code changes**
3. **Run the bump script** — only if the current version is already pushed (i.e. no unpushed commits exist):
   ```
   npm run bump <version> <slug>
   ```
4. **Write the changelog** — fill in `changelogs/<date>-<slug>.md` created by the bump script
5. **Give the user the commit message as plain text** — do not run `git commit`

## Version Bump Rules

- **Bump once per commit batch** — if unpushed local commits already exist, do NOT run `npm run bump` again; only update the existing changelog to reflect any additional changes
- **Always check before bumping** — run `git log --oneline origin/main..HEAD` and `git status`; if there are unpushed commits, the version is already bumped for this batch
- **Never bump manually** — always use `npm run bump <version> <slug>`; it updates `package.json`, `package-lock.json`, and `launcher` atomically

## Linked Files

`scripts/install.sh` and `scripts/deb/postinst` contain heavily overlapping logic. **Always edit both in parallel** — never change one without checking and mirroring the change in the other.

## GitHub Actions Versions

Always check actual latest versions via GitHub MCP (`mcp__github__get_latest_release`) before writing any workflow file. Do NOT use context7 or existing project files as version reference — they lag behind.
