# EasySanalune Workspace Instructions

## Scope

These instructions apply to the EasySanalune addon workspace.

## Required reading order

Before changing addon code, read the existing documentation in `docs/` that matches the area you are touching.
If the task affects MJ networking, read `docs/PROTOCOL.md` and `docs/MJ_WINDOW.md` first.
If the task affects buffs, read `docs/BUFF_RULES.md` first.
If the task affects fiche or export/import, read `docs/FICHE.md` first.

## Function documentation

The generated function references live in `docs/functions/`.
When Lua files are added or function signatures change, regenerate them with:

`C:\\Users\\loicf\\AppData\\Local\\Python\\pythoncore-3.14-64\\python.exe docs/functions/generate_function_docs.py`

## Persistent repo memory

Project memory files live in `docs/memory/`:

- `recent-memory.md`: rolling 48h operational context
- `long-term-memory.md`: confirmed preferences and stable decisions
- `project-memory.md`: current project status and active work
- `new-learnings.md`: compact lessons worth consolidating later

When the user says `fais la memoire`, run the `consolidate-memory` skill and update these files.
After any meaningful repo coding task, update the relevant memory files before ending the task:

- `recent-memory.md` for fresh session context and verified changes
- `project-memory.md` for current active state, next actions, and notable implementation decisions
- `long-term-memory.md` only for stable, confirmed conventions or preferences
- `new-learnings.md` only for short lessons learned from debugging or implementation

## Research workflow

Use the `research-scout` skill to capture interesting external findings or ideas.
Use the `research-review` skill to turn raw findings into accepted, rejected, or deferred decisions.
The workspace hook scheduler can remind the agent up to three times per day to run `research-scout` while the agent stays active.
When the user asks for repo code changes, apply this workflow automatically:

1. Decide whether external or API research is needed.
2. If the task depends on external behavior, uncertain APIs, protocol references, or repo-wide design tradeoffs, run `research-scout` before coding.
3. If scouting produced findings worth choosing from, or if coding introduced a design decision, run `research-review` before finalizing.
4. Update the memory files to reflect the outcome.

## Writing fingerprint guard

Before modifying repository files, run the fingerprint guard on any long French prose you are about to add or replace.
The guard script is `fingerprint_check.py`.
Avoid robotic, corporate, inflated, or generic AI phrasing.
Prefer direct French, precise wording, and short sentences.

## WoW addon conventions

Preserve Retail 9.2.7 compatibility.
Do not add third-party dependencies for runtime addon code.
Do not edit bundled libraries in `libs/` unless the task explicitly requires it.
Keep protocol changes backward-aware and documented in `docs/PROTOCOL.md`.
If Lua functions are added, removed, or renamed, regenerate `docs/functions/` before finishing the task.