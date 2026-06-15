# tpk-autonomous-skill

A Claude Code **plugin** (with a cross-platform **skill** core) that frames building a new software product as **one
gated, state-tracked, 7-phase assembly line** — from goal-setting all the way to a continuous **Loki Mode autonomous
build**. It drives one phase at a time: drafts that phase's key document using the most effective structure, lists
what's still missing (and whether it's researchable), runs an MCP preflight, persists state as memory, and only
advances through a gate.

Works in **Claude Code** (slash commands `/tpk:*`) and **Cowork** (the bundled skill triggers from natural language).

## The 7-phase line

```
[0] Goal → [1] Initial data → [2] Expert notebooks → [3] Analysis 🚦Go/No-Go
   → [4] Planning 🚦Readiness → [4.5] De-risk → [5] Autonomous build → [6] Review 🚦UAT → [7] Production/Deploy
```

The goal of phases 0–4.5 is to make the upstream docs (PRD, epics & stories, architecture) good enough that **phase 5
runs to completion unattended** — the owner reviews the running system once it has shape, not every document.

---

## Install in Claude Code (from this repo)

This repo ships its own marketplace catalog (`.claude-plugin/marketplace.json`), so it installs in two steps —
add the marketplace, then install the plugin:

```text
/plugin marketplace add teeppiphat/tpk-autonomous-skill
/plugin install tpk-autonomous-skill@tpk
/reload-plugins
```

- The marketplace registers under the name **`tpk`**, so the plugin id is **`tpk-autonomous-skill@tpk`**.
- Prefer an explicit git URL? Either of these works in place of the `owner/repo` form:
  ```text
  /plugin marketplace add git@github.com:teeppiphat/tpk-autonomous-skill.git
  /plugin marketplace add https://github.com/teeppiphat/tpk-autonomous-skill.git
  ```
- Pin to a branch/tag by appending `#<ref>`, e.g. `…/tpk-autonomous-skill.git#main`.

Verify the install with `/tpk:preflight`. To update later: `/plugin marketplace update tpk` then `/reload-plugins`.

### Local / development install

Cloned the repo and want to run it without GitHub? Point the marketplace at the local folder:

```text
/plugin marketplace add ./tpk-autonomous-skill
/plugin install tpk-autonomous-skill@tpk
/reload-plugins
```

## Install in Claude Cowork

Cowork uses skills directly (no marketplace step). Either package the skill and install it, or drop the
`skills/tpk-pipeline/` folder into your Cowork skills directory. Then trigger it in plain language, e.g.
*"start the product pipeline for &lt;idea&gt;"*.

## Commands (Claude Code)

| Command | Does |
|---|---|
| `/tpk:start [idea]` | Start or resume the pipeline; preflight + begin current phase |
| `/tpk:status` | Where are we — phase, gates, open gaps, next action |
| `/tpk:next` | Advance to the next phase (only if the gate is met) |
| `/tpk:clear [scope]` | Clear pipeline state — all / one phase / gaps only (never deletes real deliverables) |
| `/tpk:preflight` | Check NotebookLM / Loki / CloakBrowser / deploy MCPs are configured |
| `/tpk:build` | Enter the continuous autonomous build (agent loop × Loki Mode) |

In Cowork use the equivalents in plain language: "start / status / next / clear / preflight / build".

## How gaps are handled

Each phase draft is followed by a gap list. **Researchable** gaps (market size, competitor facts, regulations) are
filled via **NotebookLM deep research**. **Non-researchable** gaps (internal numbers, pricing, customer-specific
files, credentials) are written to `pipeline/<phase>/NEEDS-INPUT.md` for the user to fill.

## State & memory

Everything lives under `pipeline/` in the project root: `state.json` (the spine) + per-phase folders. State survives
new sessions and context compaction, and can be cleared per phase. **No secrets in `pipeline/`** — gitignore it.

## External tools (preflight checks these)

- **NotebookLM** — `notebooklm-mcp-cli` (`nlm` + `notebooklm-mcp`): `uv tool install notebooklm-mcp-cli` → `nlm login` → `nlm setup add claude-code`
- **Loki Mode** — `bun install -g loki-mode` → `loki doctor`
- **CloakBrowser + Playwright** — via the cartography harness (`npm install`, `npm run serve`, CDP on :9222)
- **Deploy MCP** — e.g. Coolify connector (for phases 6–7)
- **Consultant (optional)** — Codex / Gemini CLI

## Layout

```
tpk-autonomous-skill/
├── .claude-plugin/
│   ├── plugin.json                  # plugin manifest
│   └── marketplace.json             # marketplace catalog (makes the repo installable)
├── commands/                        # /tpk:start, status, next, clear, preflight, build
├── scripts/preflight.sh             # read-only readiness check
├── skills/tpk-pipeline/
│   ├── SKILL.md                     # orchestrator / control loop (works in CC + Cowork)
│   ├── references/
│   │   ├── pipeline-phases.md       # per-phase inputs, doc structures, gates
│   │   ├── state-protocol.md        # state.json schema, memory, clearing
│   │   ├── mcp-preflight.md         # which tool per phase + how to verify/fix
│   │   ├── notebooklm-research.md   # deep research + expert-notebook workflow
│   │   └── loki-autonomous-build.md # phase 5: agent loop × Loki + quality stack
│   └── assets/
│       ├── state.template.json
│       └── needs-input-template.md
└── README.md
```
