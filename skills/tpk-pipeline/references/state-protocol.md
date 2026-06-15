# State & Memory Protocol

The pipeline must survive context compaction, new sessions, and long gaps. State lives on disk under `pipeline/`
in the project root and is the single source of truth for "where are we and what's left?".

## Layout

```
pipeline/
├── state.json                     # the spine — see schema below
├── 00-goal/                       # per-phase memory folders
│   ├── NEEDS-INPUT.md             # gaps the user must fill (if any)
│   └── notes.md                   # decisions, assumptions, links
├── 01-initial-data/
│   └── NEEDS-INPUT.md
├── 02-expert-notebooks/
│   └── notebooks.md               # notebook id ↔ topic map
└── ...                            # one folder per phase touched
```

Rules:
- `pipeline/` holds **state and pointers**, never the actual deliverables. Real documents live in `docs/`,
  `research/`, `evals/`, `captures/`. State references them by path.
- **Never** store secrets, tokens, or credentials in `pipeline/`. Add `pipeline/` to `.gitignore` if state should
  stay local.

## state.json schema

Initialize from `assets/state.template.json`. Shape:

```json
{
  "product": "<one-line product name/definition>",
  "level": 4,
  "current_phase": "00-goal",
  "updated_at": "ISO-8601",
  "phases": {
    "00-goal":        { "status": "in_progress", "doc": "docs/00-goal.md", "gaps_open": 0, "gate_passed": false },
    "01-initial-data":{ "status": "pending",     "doc": null,              "gaps_open": 0, "gate_passed": false }
  },
  "notebooks": [ { "id": "nb_...", "topic": "competitor X expert" } ],
  "decisions": [ { "phase": "03-analysis", "decision": "go", "why": "...", "at": "ISO-8601" } ],
  "preflight": { "notebooklm": "ok", "loki": "missing", "playwright": "unknown" }
}
```

- `status`: `pending | in_progress | blocked | done`. `blocked` means waiting on `NEEDS-INPUT.md` or research.
- `gate_passed`: only `true` after the gate criteria in `pipeline-phases.md` are met (hard gates via AskUserQuestion).
- `decisions[]`: append the two hard-gate outcomes (Go/No-Go, Readiness) and any other material choice, so a
  resumed session knows why things are the way they are.
- `preflight`: last known MCP/CLI readiness (`ok | missing | unknown`), refreshed by the preflight step.

## Update discipline

- After **every** meaningful step (draft written, gap found, research imported, gate decided), write `state.json`.
  This is cheap and makes the pipeline resumable mid-phase.
- Keep `decisions[]` and the current task objective rich enough that, after a compaction, you can re-orient from
  `state.json` alone without re-reading every document.

## Clearing

Clearing is destructive to **state**, never to the user's real deliverables (unless they explicitly ask). Always
confirm scope first:

- **All:** reset `state.json` to the template and remove `pipeline/<phase>/` folders → start the pipeline over.
- **One phase:** reset just that phase's entry to `pending` and clear its folder → redo that phase.
- **Gaps only:** delete the `NEEDS-INPUT.md` files but keep progress → useful after the user has supplied inputs.

After clearing, report the new state and the resulting current phase.

## Resuming

On invocation: read `state.json` → announce current phase, gates passed, and open gaps → run the control loop from
SKILL.md. If `state.json` is absent, treat it as a fresh start at phase 0.
