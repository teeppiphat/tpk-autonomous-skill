# Pipeline Phases — required inputs, document structures, gates

The authoritative per-phase spec. For each phase: **purpose**, **MCP needed**, **required inputs** (the checklist
you compute gaps against), **most-effective document structure**, **output path**, **gate**.

Document structures here are condensed and domain-agnostic. Use `<product>`, `<competitor>`, `<design-partner>` as
placeholders. When a BMAD skill exists for a document (product brief, PRD, architecture, UX, stories), invoke it to
generate — these structures are what "good" looks like so you can review the output.

## Table of contents
- [Phase 0 — Goal](#phase-0--goal)
- [Phase 1 — Initial data](#phase-1--initial-data)
- [Phase 2 — Expert notebooks](#phase-2--expert-notebooks)
- [Phase 3 — Analysis](#phase-3--analysis-) 🚦
- [Phase 4 — Planning](#phase-4--planning-) 🚦
- [Phase 4.5 — De-risking & validation](#phase-45--de-risking--validation)
- [Phase 5 — Autonomous build](#phase-5--autonomous-build) → see `loki-autonomous-build.md`
- [Phase 6 — Customer review & iterate](#phase-6--customer-review--iterate-) 🚦
- [Phase 7 — Production readiness & deploy](#phase-7--production-readiness--deploy)

---

## Phase 0 — Goal
- **Purpose:** Lock a single, sharp statement everything else expands from.
- **MCP needed:** none.
- **Required inputs:** what `<product>` is (1 sentence) · who uses it · the problem · rough in/out scope · rough success criteria.
- **Document structure** (`docs/00-goal.md`):
  1. One-line definition (what / for whom / problem solved)
  2. Primary users (rough personas)
  3. Problem & why now
  4. In scope / Out of scope (initial)
  5. Rough success criteria
- **Do NOT** list features or tech stack yet.
- **Gate:** the one-liner is unambiguous and the user agrees. Then phase 1.

## Phase 1 — Initial data
- **Purpose:** Gather raw truth before any requirement is written.
- **MCP needed:** NotebookLM (deep research); optional Cartography harness (CloakBrowser/Playwright) for competitor capture.
- **Required inputs / sub-deliverables:**
  - **Market size** (TAM/SAM/SOM, CAGR, # players) → `research/docs/market-research.md` *(researchable)*
  - **First customer workflow** (if a design partner exists): current tools, manual steps, pain points, real forms/formulas → `research/supporting-documents/` *(needs-user-input — ask for files)*
  - **Competitor system capture** (optional but powerful): crawl a rival web app into a clickable map → `captures/<target>/<run_id>/viewer.html`
  - **Deep research, 14-point per competitor** → `research/competitors/<category>/<name>.md` + synthesis `research/competitor-synthesis.md` *(researchable)*
- **14-point competitor framework:** company & product overview · features (core vs add-on, present/absent) · pricing · value proposition · business model · target segment & persona · market share/status · user journey · jobs-to-be-done · user feedback/quotes · pain points · top feature requests · opportunity assessment · SWOT.
- **Confidence markers** in research docs: 🔵 fact-checked · 🟡 estimate · ❌ no data.
- **Cartography capture (if used):** `npm run serve` (CloakBrowser, leave running) → trigger crawl → on login wall, user logs in + says "continue" (`--phase authenticated`) → `build_index.mjs` → `build_viewer.mjs`. Output: `run.yaml`, `index.json`, `nodes/`, `screenshots/`, `viewer.html`. Structure is byte-stable; screenshots best-effort.
- **Gate:** market sized, competitors synthesized, white-space gaps named, customer workflow captured (if partner exists). Then phase 2.

## Phase 2 — Expert notebooks
- **Purpose:** Split the research into non-overlapping NotebookLM notebooks, each one a single-topic **expert** that answers only from sources, with citations. Later phases consult these experts.
- **MCP needed:** NotebookLM (`notebooklm-mcp`). Preflight required.
- **Required inputs:** the phase-1 research files to load as sources.
- **Procedure:** per topic → `notebook_create` → `source_add` the relevant files → `chat_configure` with the expert persona (template in `notebooklm-research.md`) → verify with a `notebook_query`. Record every notebook id in `pipeline/state.json`.
- **Output:** notebook ids + topic map in `pipeline/02-expert-notebooks/notebooks.md`.
- **Gate:** every research domain has a configured expert notebook that answers with citations. Then phase 3.

## Phase 3 — Analysis 🚦
> BMAD Phase 1. Skills: `business-analyst`, `creative-intelligence`.

- **Purpose:** Understand the problem deeply enough to decide go / no-go.
- **MCP needed:** NotebookLM (consult experts); optional Codex/Gemini as a second-opinion consultant.
- **Sub-deliverables, structures & paths:**
  - **Brainstorm** (`docs/brainstorm-*.md`): Session Objective → Techniques (5 Whys / SCAMPER / SWOT / Six Hats) → Ideas (grouped, impact/feasibility) → Summary Stats → Top Insights → Risks → Items needing research → Next Steps. *During brainstorm, consult the expert notebooks and a consultant model.*
  - **Product Brief** (`docs/product-brief-*.md`), 12 sections: Executive Summary · Problem Statement · Target Users (+ needs Must/Should/Nice) · Proposed Solution (capabilities, UVP, **Minimum Viable Solution**) · Success Metrics · Market & Competition · Business Model & Pricing · Technical Considerations · Risks & Mitigation · Resource Estimates · Dependencies · Next Steps (+ appendix: sources, interviews).
  - **Value Proposition Canvas** (`docs/value-proposition-canvas.md`): Customer Profile (jobs/pains/gains) ↔ Value Map (products/pain relievers/gain creators).
  - **Business Model Canvas** (`docs/business-model-canvas.md`): 9 blocks.
  - **Feasibility Study** (`docs/feasibility-study.md`), 5 dimensions: Market · Production · Law & Regulation (incl. data-protection law e.g. PDPA/GDPR + industry rules) · Business Model · Financial.
- **Gate (HARD, use AskUserQuestion):** 🚦 **Go / No-Go.** Enough signal to decide whether to invest. If no-go, stop here cheaply.

## Phase 4 — Planning 🚦
> BMAD Phase 2/3. Skills: `product-manager`, `system-architect`, `ux-designer`.

- **Purpose:** Produce requirements that are actually implementable — rich enough to feed an autonomous build.
- **MCP needed:** none required; `xlsx` skill for the financial model.
- **Sub-deliverables (in order):**
  1. **Tech-stack target** (`docs/tech-stack-target.md`): projected users yr1–3, budget/cost ceiling, platform (web/mobile/both), data. *Set before PRD.*
  2. **PRD** (`docs/prd-*.md`) — write **two levels: MVP and Full** via Release Planning. Structure: Document Control · Approvals · Executive Summary · Project Overview · Goals · Personas · **Functional Requirements** (FR-IDs + MoSCoW + acceptance criteria) · **Non-Functional Requirements** (perf/security/scalability/reliability/usability/maintainability + measurement) · **Epics & Stories** (As a…/I want…/So that… + Given/When/Then + points) · UX Requirements · Success Metrics (+ **analytics events per KPI story**) · Assumptions & Dependencies · Constraints · Out of Scope · **Release Planning (MVP/Enhancement/Optimization)** · Risks · Traceability Matrix · Appendix.
  3. **Architecture** (`docs/architecture-*.md`), 10 parts: System Overview · Pattern (+rationale) · Components · Data Model (ERD) · API Specs · NFR Mapping · Technology Stack (+alternatives) · Trade-offs · Deployment Architecture · Future/scalability path. *Verify the stack meets the user & cost targets.*
  4. **UX — two versions:** `docs/ux-design-mvp.md` (build round 1) and `docs/ux-design-full.md` (review/roadmap). Structure: Overview · Personas · User Flows · Wireframes (per screen) · Component Specs · **Accessibility (WCAG)** · Responsive · Design Tokens · Handoff.
  5. **Full System Sitemap** (`docs/sitemap.md`) — every surface (web app, admin, mobile, chat channel, etc.).
  6. **System Overview Diagram** (`docs/system-overview-diagram.md`, Mermaid).
  7. **Financial model 36 months** (`docs/financial-model-36m.xlsx`): assumptions (customers month-1 → month-36, cost per item, sell price model, headcount); let the model fill the rest, user adjusts.
  8. **Epics & Stories** from PRD + Architecture → `docs/stories/STORY-*.md` (story, acceptance criteria, technical notes, dependencies, testing, Definition of Done).
- **Gate (HARD, use AskUserQuestion):** 🚦 **Readiness check** — PRD ↔ Architecture ↔ UX ↔ Stories are cohesive (`docs/gate-check-*.md`). This gate's quality is what makes the autonomous build able to run unattended.

## Phase 4.5 — De-risking & validation
- **Purpose:** Prove the risky unknowns and validate domain logic *before* committing the full build — shift-left.
- **MCP needed:** optional (spike may use any tool); NotebookLM/consultant for design questions.
- **Sub-deliverables:**
  - **Technical spikes** for 3–5 highest-risk assumptions (special integrations, AI features, complex formulas, heavy queries) → `docs/spikes/<topic>.md` + ADR (use `engineering:architecture`).
  - **Data-model & domain-rule validation** against the design partner's real documents: reproduce their current results (e.g. recompute a formula to match their spreadsheet), test edge cases → `docs/data-model-validation.md`. Do this **before** locking PRD/architecture.
  - **AI eval set** for any probabilistic feature → `evals/<feature>/{cases,expected,threshold.yaml}` (e.g. accuracy ≥ X%). This becomes a build gate.
- **Gate:** risky assumptions proven or re-planned; data model reproduces reality; eval thresholds defined. Then phase 5.

## Phase 5 — Autonomous build
See **`references/loki-autonomous-build.md`** (full procedure). Precondition: phase 4 Readiness gate passed + phase 4.5 done.

## Phase 6 — Customer review & iterate 🚦
- **Purpose:** Put the running system in front of real users and turn feedback into the next round.
- **MCP needed:** deploy MCP (for a preview/staging environment); Playwright/CloakBrowser for re-test.
- **Steps:** deploy to a **preview environment** users can click → collect feedback → convert to new stories → build → re-test. Re-prioritize from `docs/ux-design-full.md` into a Now/Next/Later roadmap (`product-management:roadmap-update`).
- **Gate (HARD):** 🚦 **UAT sign-off** — users test against acceptance criteria and formally accept → `docs/uat-signoff.md`.

## Phase 7 — Production readiness & deploy
- **Purpose:** Make it safe and durable in production, then ship.
- **MCP needed:** deploy MCP (e.g. Coolify); observability/load/security tooling.
- **Sub-deliverables / checks:**
  - **Observability & incident response:** centralized logging, error tracking, uptime + alerting tied to NFRs, runbook (`engineering:incident-response`).
  - **Performance / load test** against the scale target from the financial model.
  - **Security & data protection (deeper than code review):** threat model, SCA/dependency CVE scan, secret scanning, data-protection law design (PDPA/GDPR: consent, retention, subject rights, encryption), pen test for user/financial data.
  - **Data migration & cutover** (if a legacy system exists): migration script + reconciliation + parallel run + rollback plan.
  - **Release pipeline** (esp. mobile): push infra, device/OS matrix, store submission, versioning/force-update.
- **Deploy:** Loki produced Dockerfile + CI/CD but does **not** deploy itself — a human runs deploy via the deploy MCP (resource discovery → compose → inject env → verify → enable monitoring). Guard credentials (see `mcp-preflight.md` and the secrets rules).
- **Gate:** monitoring live, tests green (unit/e2e/security/eval), migration reconciled. Shipped.
