---
description: Advance the TPK pipeline to the next phase (only if the current gate is met)
---

Follow the `tpk-pipeline` skill (`${CLAUDE_PLUGIN_ROOT}/skills/tpk-pipeline/SKILL.md`).

1. Load `pipeline/state.json`.
2. Re-check the current phase's gate criteria (see `references/pipeline-phases.md`). For the two HARD gates
   (after Analysis = Go/No-Go, after Planning = Readiness), confirm explicitly with `AskUserQuestion`.
3. If gaps remain, do NOT advance — show the outstanding `NEEDS-INPUT.md` items or run the pending research first.
4. If the gate is met: mark it passed, set the next phase to `in_progress`, run preflight for the new phase, and
   begin its draft → gap → gate loop.
5. Persist `state.json`.

The user has often just supplied missing inputs or finished research; treat `/tpk:next` as "I'm ready, continue."
$ARGUMENTS
