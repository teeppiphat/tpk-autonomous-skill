# Phase 5 — Autonomous Build (Agent Loop × Loki Mode)

The payoff of the whole pipeline. Drive the build **continuously to completion** by combining the Claude Code
**agent loop** with **Loki Mode**'s autonomy + quality stack. Working assumption: the upstream documents (PRD,
epics & stories, architecture) passed the Readiness gate and the risky unknowns were de-risked, so they are good
enough to run unattended. The **owner reviews the running system once it has shape** — far easier than reading every
document and babysitting each story.

## Preconditions (verify before starting)
- Phase 4 Readiness gate passed (`docs/gate-check-*.md`); PRD ↔ architecture ↔ stories cohesive.
- Phase 4.5 done: spikes resolved, data model validated, **AI eval sets exist** for probabilistic features.
- Preflight green: Loki installed (`loki doctor`), Playwright MCP + CloakBrowser available (`npm run serve` running,
  CDP on :9222), provider authenticated.
- Git repo initialized (Loki checkpoints every task). `.loki/` is gitignored. No secrets in the tree.

## How the two layers fit together

- **Agent loop** = the outer driver that keeps Claude working turn after turn without handing control back, until
  the task is done or a budget limit is hit. Configure it for unattended runs:
  - `permission_mode`: `acceptEdits` on a dev machine, or `bypassPermissions` only in an isolated/sandbox/CI
    environment. Never `bypassPermissions` on a machine with real credentials/systems.
  - `max_turns` / `max_budget_usd`: set a ceiling so an open-ended build can't run away silently. On hitting the
    limit the loop returns `error_max_turns` / `error_max_budget_usd` — resume with a higher cap to continue.
  - `effort`: `high`/`xhigh` for build & debugging.
  - Hooks: `Stop` = run the review/quality gate before the session is allowed to end; `PreToolUse` = block
    dangerous commands; `SubagentStop` = aggregate per-story results.
  - Persist rules in `CLAUDE.md` (re-injected every request, survives compaction), not just the opening prompt.
- **Loki Mode** = the engine inside that runs the RARV-C closure loop and the quality gates so "done" means
  *verified*, not *attempted*. Start it on the BMAD artifacts directly:

```bash
loki doctor
loki plan ./docs/prd-*.md        # complexity, cost, iteration estimate — set the loop budget from this
loki start --bmad-project .      # reads FR-format reqs, Given/When/Then ACs, epics & stories
loki dashboard                   # localhost:57374 — watch agents/queue/gates live
```

The agent loop keeps the session alive and bounded; Loki supplies the RARV-C iterations, the agent team, and the
gates. Together: a continuous, bounded, self-verifying build.

## The layered quality stack (every story passes all of it)

1. **RARV-C cycle** — Reason (read `.loki/CONTINUITY.md` + learnings + queue) → Act (code + atomic git checkpoint) →
   Reflect (update memory) → Verify (run tests; on fail, log learning, rollback to last good checkpoint, retry) →
   Critique (override council judges before the iteration closes).
2. **11 quality gates** — input guardrails · static analysis · 3-reviewer blind review · anti-sycophancy
   (Devil's Advocate on unanimous pass) · output guardrails (no secrets) · severity blocking (Critical/High/Medium
   = BLOCK) · test coverage (unit 100% pass, >80% cov; integration 100%) · mock detector · test-mutation detector ·
   backward compatibility · documentation coverage. Code is not "done" until all pass.
3. **AI eval gate (added)** — for any story touching a probabilistic feature, run the phase-4.5 eval set
   (`evals/<feature>/`); below the accuracy/error threshold = BLOCK, the same as any other gate. Unit tests passing
   is **not** sufficient for AI features.
4. **Human gate on high-risk modules (added)** — modules where a wrong result causes real damage (money/billing,
   permissions/authz, anything handling personal data) must **pause for owner review before merge**. Mark these in
   the stories; do not let pure autonomy ship them. (Loki itself flags that complex domain logic may need human review.)
5. **Per-story UI test (Playwright MCP + CloakBrowser)** — after a story's dev completes, exercise the real flow
   before moving on: `cloak_launch` → `cloak_navigate` → `cloak_snapshot` (get `@eN` refs) → `cloak_click`/`cloak_type`
   per acceptance criteria → `cloak_screenshot` (evidence) → `cloak_read_page` (verify). Pass → commit + next story;
   fail → back into RARV to fix. Only advance to the next story once the current one is verified.

## Running it continuously

- Let the loop iterate story-by-story under the gates. It self-corrects on failure (rollback + retry with a recorded
  learning) instead of stopping.
- Budget guard: derive `max_turns`/`max_budget_usd` from `loki plan`; when hit, the loop pauses cleanly — review,
  then resume the session to continue. Watch the dashboard for stuck/oscillation escalations.
- Owner touchpoints are intentionally few: (a) human-gate pauses on high-risk modules, (b) when the system first
  takes shape (review the running app), (c) budget-limit pauses. Otherwise it runs.

## Outputs & where they live
- Git repo: source, tests, Dockerfile, CI/CD.
- `.loki/CONTINUITY.md` (working memory), `.loki/state/`, `.loki/queue/`, `.loki/quality/test-results.json`,
  `.loki/metrics/`, audit logs.
- Update `pipeline/state.json`: phase 5 status, build start commit, gate results.

## After the build takes shape
Hand to **phase 6** (customer review on a preview env → iterate → UAT sign-off), then **phase 7**
(production readiness → deploy). Loki generates deploy configs but does **not** deploy; a human runs deploy via the
deploy MCP. See `pipeline-phases.md`.
