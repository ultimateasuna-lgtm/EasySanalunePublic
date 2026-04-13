---
name: research-scout
description: "Use when the user asks for research, scouting, API checking, external documentation review, or when a coding task depends on uncertain external behavior before implementation. Trigger phrases: research-scout, scout, veille, recherche, API WoW, Blizzard UI source, doc externe."
---

# research-scout

Use this skill to collect external information relevant to EasySanalune without immediately changing addon code.

## Goal

Produce a compact scouting note that can later be reviewed and either adopted or discarded.

## Sources

- WoW API references
- Blizzard UI source
- Warcraft Wiki API pages
- existing addon docs in this repo

## Workflow

1. Define the research question precisely.
2. Collect only relevant facts, API details, patterns, and risks.
3. Separate verified facts from assumptions.
4. Save the result in a repo doc when the user asks for persistence.
5. If the result affects future work, add a short line to `docs/memory/recent-memory.md`.
6. If the research will influence a coding choice, hand off to `research-review` before the task is closed.

## Expected output

- Question
- Verified findings
- Risks or unknowns
- Suggested next action
- Suggested review decision path