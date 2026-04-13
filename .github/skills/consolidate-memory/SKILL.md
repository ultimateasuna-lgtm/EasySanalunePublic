---
name: consolidate-memory
description: "Use when the user says fais la memoire, asks to update project memory, or after a meaningful coding task on the repo to refresh recent-memory, project-memory, long-term-memory, and new-learnings as needed."
---

# consolidate-memory

Use this skill when the user says `fais la memoire` or asks to consolidate recent work into persistent repo notes.

## Goal

Keep `docs/memory/` concise, current, and useful across sessions.

## Files to update

- `docs/memory/recent-memory.md`
- `docs/memory/project-memory.md`
- `docs/memory/long-term-memory.md`
- `docs/memory/new-learnings.md`

## Workflow

1. Read the existing files in `docs/memory/`.
2. Review the recent conversation context, changed files, and newly added docs.
3. Move only stable information into `long-term-memory.md`.
4. Keep `recent-memory.md` focused on the last 48h of work.
5. Keep `project-memory.md` focused on active implementation state, blockers, next actions, and verification status.
6. Append short, concrete lessons to `new-learnings.md` when something was discovered experimentally.
7. Remove stale or contradicted notes instead of stacking duplicates.
8. After a coding task, do not update every memory file blindly; update only the files justified by the work actually completed.

## Output quality rules

- Write in direct French.
- Prefer short bullets or short sections.
- Do not turn memory files into changelogs.
- Record decisions, constraints, verified commands, and important caveats.