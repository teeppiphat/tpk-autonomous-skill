---
name: tpk-pipeline
description: >-
  Drive a brand-new software product from idea to autonomous build as ONE gated, state-tracked,
  7-phase assembly line (goal → research → expert notebooks → analysis → planning → de-risk → autonomous build → production).
  Work ONE phase at a time: draft that phase's key document using the most effective structure, list what's
  still missing (and whether it's researchable), persist state to disk as memory, run an MCP preflight before any
  phase that needs a connector, and only move forward through an explicit gate. Use this whenever the user is
  starting a new product/system, wants to "run the pipeline / playbook", says things like "ทำตั้งแต่ต้นจนจบ",
  "เริ่มโปรเจกต์ใหม่", "ขับเคลื่อนงานตาม playbook", "ทำ PRD แล้วให้ build เอง", "autonomous build", references a
  product brief / PRD / epics & stories, or asks to hand off a spec to Loki Mode. Trigger even if they don't name
  every step — this skill owns the whole flow and its state.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent, TaskCreate, TaskUpdate, AskUserQuestion, WebSearch, WebFetch
---

# TPK Autonomous Product Pipeline

Turn a product idea into shipped software through **one continuous assembly line of 7 phases**. Each phase
produces a checkable document, and the line only advances through explicit **gates**. The whole point is that by
the time you reach the autonomous build, the upstream documents are good enough that the build can run
**to completion on its own** — the owner reviews the running system once it takes shape, instead of reading every
document by hand.

This skill is the **orchestrator/state machine**. It is platform-agnostic: in Claude Code it is also driven by the
`/tpk:*` slash commands; in Cowork it runs from natural language. The behavior is identical either way.

## The assembly line

```
[0] Goal            → docs/00-goal.md
[1] Initial data    → research/ (market, customer workflow, competitor capture, deep research)
[2] Expert notebooks→ NotebookLM (1 notebook = 1 expert), wired via notebooklm-mcp
[3] Analysis        → brainstorm, product brief, canvases, feasibility        🚦 Go / No-Go
[4] Planning        → tech-stack, PRD (MVP+Full), architecture, UX, sitemap, financial 36m, epics & stories  🚦 Readiness
[4.5] De-risk       → spikes, data-model validation, AI eval set defined
[5] Autonomous build→ agent loop + Loki Mode (RARV-C + 11 gates + AI-eval gate + human gate + Playwright/CloakBrowser)
[7] Production       → observability, load, security/PDPA, migration → deploy
```

Full per-phase detail — purpose, required inputs, **the most effective document structure**, output path, and gate
criteria — lives in `references/pipeline-phases.md`. Read it whenever you enter or resume a phase.

## Operating principles (read once, apply every phase)

1. **One phase at a time.** Never draft phase N+1 while N's gate is open. The user can see exactly where they are.
2. **Gate-driven.** A phase ends only when its gate criteria are met (or the user explicitly overrides). Gates exist
   so the user can stop cheaply before sinking cost into the next phase.
3. **State is memory.** Persist progress to `pipeline/state.json` plus per-phase folders, so the pipeline survives
   context loss, compaction, and new sessions. See `references/state-protocol.md`. Sometimes the user wants to
   **clear** state (start over, or redo one phase) — support that explicitly.
4. **MCP preflight before connector work.** Several phases need an external tool (NotebookLM, Playwright/CloakBrowser,
   Loki, deploy MCP). Before starting such a phase, verify the tool is configured and usable. If not, tell the user
   exactly how to set it up before proceeding. See `references/mcp-preflight.md`.
5. **Draft, then expose the gaps.** For every phase: draft the document from what the user already gave you, then
   produce an explicit **gap list**. Classify each gap as *researchable* or *needs-user-input* (next section).
6. **Don't fabricate.** A drafted document with honestly-marked gaps (🟡/❌) is far more useful than a confident
   document full of invented facts. Mark assumptions clearly.

## The control loop

Run this every time the skill is invoked or the user says "continue / next / status":

1. **Load state** from `pipeline/state.json` (create it from `assets/state.template.json` if missing).
2. **Report position:** current phase, gates passed, outstanding gaps. (This is what `/tpk:status` shows.)
3. **Preflight** any MCP the current phase needs (`references/mcp-preflight.md`). Block and instruct if missing.
4. **Open the phase spec** in `references/pipeline-phases.md` for the current phase: its required inputs + the
   document structure to use.
5. **Draft the phase document** at its output path, using only what the user has supplied + what you can verify.
6. **Compute gaps** against the required-inputs checklist. For each gap, decide:
   - **Researchable** (market size, competitor facts, industry/regulatory norms, public reviews) → handle via
     NotebookLM deep research (`references/notebooklm-research.md`): offer it, or just do it (create the notebook,
     run research, import sources, configure the expert persona, query, fold findings back into the document).
   - **Not researchable** (internal numbers, customer-specific workflow, pricing decisions, headcount, credentials,
     business choices) → append to a single human-facing file `pipeline/<NN>-<phase>/NEEDS-INPUT.md`
     (template: `assets/needs-input-template.md`) and tell the user what to fill in.
7. **Update state:** record the document path, gaps, decisions, and gate status. Persist key decisions into
   `state.json` so they survive compaction.
8. **Gate:** present the draft + the gap list, state the gate criteria, and either advance (user satisfied / gate met)
   or hold (waiting on inputs/research). Use `AskUserQuestion` for explicit go/no-go at the two hard gates
   (after Analysis, after Planning Readiness).

Repeat phase by phase until the **Planning gate + De-risk** are complete and the inputs are rich enough to hand to
the autonomous build. That handoff is the whole goal of phases 0–4.5.

## Gap handling cheat-sheet

| Kind of missing info | Example | Action |
|---|---|---|
| Public / external fact | market size, a competitor's pricing, regulation, app-store reviews | NotebookLM deep research → fold into doc, cite |
| Competitor system structure | how a rival's app is laid out | Cartography harness capture (see phase 1) |
| Internal / decision | target customer counts, sell price, headcount, brand choices | `NEEDS-INPUT.md` list for the user |
| Customer-specific | a design partner's real forms, formulas, current workflow | `NEEDS-INPUT.md` (ask user to provide files) |

When in doubt whether something is researchable: try a quick scoped search/notebook query first; if it can't be
sourced publicly, move it to `NEEDS-INPUT.md`.

## Phase 5 — the autonomous build (the payoff)

When the planning documents (PRD, epics & stories, architecture) have passed the Readiness gate and the risky
unknowns are de-risked, hand off to a **continuous autonomous build** that combines the Claude Code agent loop with
Loki Mode. Assume the upstream docs are good enough to run unattended; the owner inspects the **running system**
once it has shape. Full procedure — agent-loop configuration, Loki invocation, and the layered quality stack
(RARV-C cycle + 11 quality gates + an AI-eval gate + a human gate on high-risk modules + Playwright/CloakBrowser
test per story) — is in `references/loki-autonomous-build.md`. Read it before starting the build.

After the build takes shape: customer review → iterate → **Production Readiness** (observability, load test,
security & data-protection, data migration) → deploy. These map to the later sections of
`references/pipeline-phases.md`.

## State & memory (quick reference)

- Working directory: `pipeline/` in the project root. Never store secrets here.
- `pipeline/state.json` — single source of truth for "where are we?" (schema in `references/state-protocol.md`).
- `pipeline/<NN>-<phase>/` — per-phase memory: the draft pointer, the gap list, notebook IDs, decisions.
- **Clearing:** `/tpk:clear` (or "clear the pipeline") — confirm scope first: everything, one phase, or just the
  gap lists. Clearing removes state files but never touches the user's real `docs/` deliverables unless they ask.
- After every meaningful step, write back to `state.json` so a fresh session can resume exactly here.

## Platform notes

- **Claude Code:** the `/tpk:*` commands are thin entry points that invoke this skill's behaviors. Slash commands
  and `${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh` are available.
- **Cowork:** no slash commands — drive everything from natural language ("start the pipeline", "what's our status",
  "move to the next phase", "clear phase 4"). MCP/connector checks use the connector UI instead of the CLI; the
  preflight reference explains both paths.

Keep the user oriented at all times: which phase, what's blocking, what you need from them next.
