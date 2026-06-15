---
description: Start or resume the TPK autonomous product pipeline (7-phase assembly line)
---

Invoke the `tpk-pipeline` skill and run its control loop.

1. Read the skill at `${CLAUDE_PLUGIN_ROOT}/skills/tpk-pipeline/SKILL.md` and follow it.
2. Load `pipeline/state.json` (create from the skill's `assets/state.template.json` if missing).
3. Run the MCP preflight for the current phase (`bash ${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh`), record results in state.
4. Announce the current phase and begin its draft → gap → gate loop, one phase at a time.

If the user gave a product idea in their message, seed `state.json.product` and start at phase 0 (Goal).

User context (optional): $ARGUMENTS
