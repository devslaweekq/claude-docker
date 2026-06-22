# Changelog conventions

This folder collects release notes and per-feature changelog entries.

---

## File naming

`YYYY-MM-DD-<short-topic>.md` - One file per feature/fix — written during development, before the version is known.

---

## Structure inside a release file (`YYYY-MM-DD-<short-topic>.md`)

```markdown
# Changelog — <one-line summary of what changed>

## [X.Y.Z] — YYYY-MM-DD

### Added
- ...

### Changed
- ...

### Fixed
- ...
```

- **Title** (`#`) — version number + short description of the release.
- **Section header** (`##`) — version in brackets + ISO date: `[1.2.4] — 2026-06-22`.
- **Categories** (`###`) — use only the ones that apply: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

---

No version number — these files are written before the release is cut.

---

## Categories (Keep a Changelog)

| Category     | Use for                            |
| ------------ | ---------------------------------- |
| `Added`      | New features                       |
| `Changed`    | Changes to existing behaviour      |
| `Deprecated` | Features marked for future removal |
| `Removed`    | Features removed in this release   |
| `Fixed`      | Bug fixes                          |
| `Security`   | Security-related fixes             |
