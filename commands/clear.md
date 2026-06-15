---
description: Clear TPK pipeline state/memory (all, one phase, or just gap lists) — never touches real deliverables
---

Follow the clearing rules in `${CLAUDE_PLUGIN_ROOT}/skills/tpk-pipeline/references/state-protocol.md`.

1. **Confirm scope first** (use `AskUserQuestion` if unclear): everything / one phase / gap lists only.
2. Clearing affects ONLY `pipeline/` state files. Never delete the user's real deliverables in `docs/`, `research/`,
   `evals/`, `captures/` unless they explicitly ask.
   - All → reset `pipeline/state.json` from the template, remove `pipeline/<phase>/` folders.
   - One phase → reset that phase entry to `pending`, clear its folder.
   - Gaps only → delete `NEEDS-INPUT.md` files, keep progress.
3. Report the new state and resulting current phase.

Requested scope (optional): $ARGUMENTS
