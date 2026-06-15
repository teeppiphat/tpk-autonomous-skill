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

## Prerequisites — install the pipeline tools (step by step)

The plugin/skill itself only needs Claude Code (or Cowork). The **phases** call external tools — install each
before the phase that needs it. You don't need everything on day one. `/tpk:preflight` checks all of them and tells
you exactly what's missing and how to fix it.

### Which tool is needed when

| Tool | Needed for | Required? |
|---|---|---|
| NotebookLM (`notebooklm-mcp-cli`) | phases 1–3 (deep research + expert notebooks) | yes, to research |
| Loki Mode | phase 5 (autonomous build) | yes, to build |
| CloakBrowser + Playwright | phase 1 (competitor capture) + phase 5 (per-story UI test) | yes for those steps |
| Deploy MCP (e.g. Coolify) | phases 6–7 (preview env + deploy) | yes to deploy |
| Codex / Gemini CLI | phases 3 & 4.5 (second-opinion consultant) | optional |

### Step 0 — Base requirements

- **Claude Code** (slash commands) *or* **Cowork** (natural-language skill) — for the plugin itself.
- **Node.js ≥ 18** and **git** — verify: `node -v` and `git --version`.
- Two install helpers used below (macOS/Linux):
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh      # uv  → for NotebookLM
  curl -fsSL https://bun.sh/install | bash             # bun → for Loki Mode (fastest)
  ```

### Step 1 — NotebookLM (phases 1–3) · required

Gives you deep research + the expert notebooks. The package ships both the `nlm` CLI and the `notebooklm-mcp` server.

```bash
uv tool install notebooklm-mcp-cli      # or: pipx install notebooklm-mcp-cli  / pip install notebooklm-mcp-cli
nlm login                               # opens a browser, extracts cookies (multi-account: nlm login switch <profile>)
nlm setup add claude-code               # register the MCP server with Claude Code
nlm doctor                              # verify install + auth
```

Notes: this MCP exposes ~35 tools — toggle it with `@notebooklm-mcp` in Claude Code to save context when idle.
Cookies expire every few weeks; re-run `nlm login` if research stops working.

### Step 2 — Loki Mode (phase 5) · required for the build

The autonomous build engine.

```bash
bun install -g loki-mode                # or: brew tap asklokesh/tap && brew install loki-mode  / npm install -g loki-mode
loki doctor                             # checks providers, git, runtime
```

Loki drives a coding-agent CLI, so make sure a provider is authenticated — an authenticated `claude` login or
`ANTHROPIC_API_KEY` in the environment.

### Step 3 — CloakBrowser + Playwright (phase 1 capture + phase 5 UI test) · required for those steps

These come with the web-app **cartography harness** repo. From that repo's folder:

```bash
npm install                             # pulls Playwright + CloakBrowser
npm run serve                           # start the stealth browser; leave running. Exposes CDP on 127.0.0.1:9222
```

`/tpk:preflight` confirms the CDP endpoint is reachable on `:9222`. Start `npm run serve` only when you actually run
a capture or a per-story UI test.

### Step 4 — Consultant (phases 3 & 4.5) · optional

A second model for second opinions during brainstorm/architecture.

```bash
npm i -g @openai/codex                  # or install the Gemini CLI
```

### Step 5 — Deploy MCP (phases 6–7) · required to deploy

Connect a deployment connector (e.g. **Coolify**) and set its credentials out-of-band (never in the repo).

- **Claude Code:** `claude mcp add <name> <command>` (or the connector UI), then `claude mcp list` to confirm.
- **Cowork:** connect it through the connector UI.

### Verify everything at once

- **Claude Code:** `/tpk:preflight` — runs `scripts/preflight.sh` (read-only) and prints a ✓/✗/! readiness table,
  with the exact remediation command for anything missing.
- **Cowork:** say *"run preflight"* — the skill checks connectors via the connector UI instead of the CLI.

Full per-tool detail and the phase→tool mapping live in `skills/tpk-pipeline/references/mcp-preflight.md`.

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
