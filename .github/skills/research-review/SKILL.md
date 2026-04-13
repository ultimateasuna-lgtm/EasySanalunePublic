---
name: research-review
description: "Use when scouting notes exist and the agent must decide adopt, defer, or reject before or after coding. Trigger phrases: research-review, review research, trancher, decision, adopter, rejeter, reporter, choix technique."
---

# research-review

Use this skill after scouting work has been collected and a decision is needed.

## Goal

Turn raw findings into an engineering decision for EasySanalune.

## Workflow

1. Read the scouting material and the impacted addon files.
2. Classify findings as `adopt`, `defer`, or `reject`.
3. Explain the reason in direct French.
4. If a direction is adopted, update `docs/memory/project-memory.md` and any affected docs.
5. If a claim is weak or unverified, keep it out of long-term memory.
6. If coding has already been done, verify the implemented direction still matches the final decision.

## Output shape

- Decision
- Why
- Impacted files or systems
- Follow-up task if any