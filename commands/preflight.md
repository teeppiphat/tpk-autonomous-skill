---
description: Check that all pipeline MCPs/CLIs are configured and usable (NotebookLM, Loki, CloakBrowser, deploy)
---

Run the preflight and interpret it for the user.

1. Execute `bash ${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh` and show the result.
2. For anything missing, give the exact remediation from
   `${CLAUDE_PLUGIN_ROOT}/skills/tpk-pipeline/references/mcp-preflight.md` (copy-paste install/auth commands).
3. Map readiness to phases: NotebookLM → phases 1–3, Loki + Playwright/CloakBrowser → phase 5, deploy MCP → phases 6–7.
4. Write the results into `pipeline/state.json.preflight`.

If running in Cowork (no `claude` CLI), check connectors via the connector UI instead and suggest connecting any
missing ones. $ARGUMENTS
