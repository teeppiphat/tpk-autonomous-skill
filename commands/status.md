---
description: Show TPK pipeline status — current phase, gates passed, open gaps
---

Read `pipeline/state.json` and report concisely:

- Product + project level
- Current phase and its status (pending/in_progress/blocked/done)
- Gates passed so far, and the next gate
- Open gaps per phase (count + where the `NEEDS-INPUT.md` files are)
- Last known MCP preflight results
- The single next action you need from the user (if any)

If `pipeline/state.json` doesn't exist, say the pipeline hasn't started and suggest `/tpk:start`.
Follow `${CLAUDE_PLUGIN_ROOT}/skills/tpk-pipeline/references/state-protocol.md` for the schema.
