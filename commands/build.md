---
description: Enter Phase 5 — continuous autonomous build (Claude Code agent loop × Loki Mode)
---

Follow `${CLAUDE_PLUGIN_ROOT}/skills/tpk-pipeline/references/loki-autonomous-build.md` exactly.

1. **Verify preconditions:** phase 4 Readiness gate passed, phase 4.5 done (spikes + data-model validation + AI eval
   sets), preflight green (Loki, Playwright/CloakBrowser running, provider authed), git repo + `.loki/` gitignored.
   If any precondition fails, stop and tell the user what's missing — do NOT start the build.
2. **Plan the budget:** `loki plan ./docs/prd-*.md` → derive `max_turns` / `max_budget_usd` for the agent loop.
3. **Run continuously:** start `loki start --bmad-project .` under the agent loop (acceptEdits on a dev machine, or
   bypassPermissions only in an isolated sandbox), with a `Stop` hook enforcing the quality gate. Layer the full
   stack per story: RARV-C + 11 gates + AI-eval gate + human gate on high-risk modules + Playwright/CloakBrowser test.
4. **Owner touchpoints only:** human-gate pauses, budget-limit pauses, and when the system first takes shape.
   Otherwise let it run to completion, self-correcting on failure.
5. Update `pipeline/state.json` (phase 5 status, start commit, gate results). On completion, hand to phase 6.

Assume upstream docs are good enough to run unattended — the owner reviews the running system, not every document.
$ARGUMENTS
