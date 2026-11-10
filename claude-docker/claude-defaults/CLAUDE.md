# User-level rules

## Environment: native Ubuntu, NOT WSL

The user's machine runs native Ubuntu (Windows is only a second OS for games). Paths like `/mnt/d/...` are just a second disk mounted in
Ubuntu, not a sign of WSL. Never assume WSL, never suggest WSL-specific explanations or Windows-side checks; treat shell output as coming
from the real host system.

## ComfyUI: draft cheap, finalize once

When generating an image via the `comfyui` MCP for preview or validation purposes (a banner, logo, icon — anything where the exact
composition/style isn't locked in yet), don't jump straight to a single full-quality render:

1. Generate 3-5 low-resolution draft variants first — fewer sampling steps and/or a smaller resolution than the final asset. Cheap and fast;
   the point is to compare directions, not to judge final fidelity.
2. Present the drafts (or a description of each) so the user can pick one, or ask for further variations.
3. Re-render only the chosen draft at full quality/resolution as the final asset.

Skip the draft round only when the user has already described the exact final image in full detail and just wants one output, or explicitly
asks for a single direct high-quality generation.

## Always give commit text, unprompted

Whenever a turn ends with uncommitted changes in the working tree, close with a proposed commit message — a single line, under 100
characters, no bulleted body — without waiting to be asked. Don't commit or push without explicit confirmation; just always have the text
ready at the end of the summary.

Write the commit message in the language and style of the repository's existing history (check `git log` first, e.g. Conventional
Commits like `fix: ...`), not in the language used for chatting with me. If there is no history to follow, default to English.

## ALWAYS ask before running any script

Before running any script — a project script, an npm/make target, a migration/seed/sync/import job, or one I wrote myself — ALWAYS
stop and ask whether I may run it, every single time. Never run it on my behalf "to see what it does". Before asking, read the script and
state in the question: what it does, what it reads and writes, which environment/credentials it would pick up (`.env`, exported vars,
config files can point at production), and whether it has a `--dry-run`/preview mode.

- A `--dry-run` flag existing is not permission to skip the question, and not running with it is never acceptable by default: propose the
  dry-run command first and run the real one only after I explicitly approve it.
- Never run a script against an environment I haven't named. If `.env` or the shell may hold credentials that could be production, say so
  and ask which target to use — don't open the `.env` to find out.
- Approval covers that one command only; it does not extend to other scripts, other arguments, or a later re-run.
- Plain read-only inspection (`ls`, `cat`, `grep`, `git status/log/diff`, `--help`) doesn't need to be asked about.
- Exception: a project's own CLAUDE.md / rules files may explicitly allow specific commands (e.g. scoped `npx nx test|build|lint <app>`).
  Run exactly those without asking. The exception never extends beyond what the project names — migrations, deploys, seed/sync/import
  jobs, `affected` across the whole repo, any other target or environment still need my approval. If the project rules are ambiguous, ask.

## Never touch `.env` files

`.env` files (`.env`, `.env.local`, `.env.production`, `.env.*` except the `.env.example`/`.env.sample` templates) contain secrets. Never
read, `cat`, `grep`, `head`, open, edit, copy, move, delete, print or paste them, and never include their contents in a command, a message,
a file or a request to an outside service. Listing that one exists is fine. To learn which variables a project expects, use
`.env.example` or the code; if that isn't enough, ask me.

Exception: a project's own CLAUDE.md / rules files may explicitly open specific non-secret env files (e.g. `.env.ci`, `.env.development`,
`.env.test`). Follow that for exactly the files named and no others; every other `.env*` file stays closed.
