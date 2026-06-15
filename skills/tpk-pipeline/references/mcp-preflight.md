# MCP / Tool Preflight

Every phase that depends on an external tool must verify it is **configured and usable** before starting. If it is
not, stop and give the user the exact setup steps — do not silently work around a missing connector. Record results
in `state.json.preflight`.

## What each phase needs

| Phase | Tool | Required? |
|---|---|---|
| 1 Initial data | NotebookLM MCP (deep research) | yes (for research) |
| 1 Initial data | Cartography harness (CloakBrowser/Playwright) | optional (competitor capture) |
| 2 Expert notebooks | NotebookLM MCP | yes |
| 3 Analysis | NotebookLM MCP; Codex/Gemini consultant | yes / optional |
| 5 Autonomous build | Loki Mode CLI; Playwright MCP + CloakBrowser | yes |
| 6 Review / 7 Deploy | Deploy MCP (e.g. Coolify) | yes for deploy |

## How to check (Claude Code)

Run the bundled script — it probes CLIs and, if available, MCP server config:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh"
```

Or check individually:

- **MCP servers configured:** `claude mcp list` — look for `notebooklm-mcp` (and any deploy MCP). Toggle in-session with `@notebooklm-mcp`.
- **NotebookLM:** `nlm doctor` (diagnoses install + auth). Not installed → `uv tool install notebooklm-mcp-cli`; then wire it: `nlm setup add claude-code`. Auth: `nlm login` (or `nlm login --check`). Multi-account: `nlm login switch <profile>`.
- **Loki Mode:** `loki doctor`. Missing → `bun install -g loki-mode` (or brew/npm). Needs an authenticated provider (Claude Code login or `ANTHROPIC_API_KEY`).
- **CloakBrowser / Playwright:** the cartography harness `npm install` provides them; `npm run serve` must be running (CDP at `127.0.0.1:9222`) for capture and for per-story UI tests.
- **Consultant (optional):** `command -v codex` / Gemini CLI.
- **Deploy MCP:** confirm the connector (e.g. Coolify) is connected and credentials are set out-of-band.

## How to check (Cowork)

No CLI. Verify connectors through the connector UI / registry instead:
- If a needed connector (NotebookLM, deploy, etc.) is not connected, search the connector registry and suggest it
  to the user, then ask them to connect it before proceeding.
- For tools that are pure CLIs (Loki, CloakBrowser via `npm run serve`), these run on the user's machine/terminal —
  instruct the user to start them, since Cowork can't launch a long-running local server itself.

## Remediation summary (copy-paste for the user)

```bash
# NotebookLM (CLI + MCP in one package)
uv tool install notebooklm-mcp-cli      # or: pipx install notebooklm-mcp-cli
nlm login                               # browser auth, cookies extracted
nlm setup add claude-code               # register the MCP server
nlm doctor                              # verify

# Loki Mode
curl -fsSL https://bun.sh/install | bash
bun install -g loki-mode
loki doctor

# Cartography harness (CloakBrowser + Playwright)
npm install
npm run serve                           # leave running; CDP on :9222
```

## Secrets rule (applies to every tool)

Never echo or commit API keys, cookies, or credentials. Use env vars / the platform's secret store. NotebookLM
cookies live under `~/.notebooklm-mcp-cli`; Loki state under `.loki/` (gitignore it). Deploy credentials stay in the
deploy platform, not in compose files or logs.
