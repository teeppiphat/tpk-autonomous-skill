#!/usr/bin/env bash
# Preflight: report whether the pipeline's external tools are installed & usable.
# Read-only — never installs or changes anything. Safe to run anytime.
set -uo pipefail

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
miss() { printf '  \033[31m✗\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "TPK pipeline preflight"
echo "======================"

echo "Runtimes:"
have node && ok "node $(node -v 2>/dev/null)" || miss "node — install Node.js >=18"
have bun  && ok "bun $(bun -v 2>/dev/null)"   || warn "bun — recommended for Loki (curl -fsSL https://bun.sh/install | bash)"
have git  && ok "git $(git --version 2>/dev/null | awk '{print $3}')" || miss "git — required for Loki checkpoints"
have uv   && ok "uv present" || warn "uv — recommended to install notebooklm-mcp-cli"

echo "NotebookLM (research + expert notebooks):"
if have nlm; then
  ok "nlm CLI present"
  nlm login --check >/dev/null 2>&1 && ok "nlm authenticated" || warn "nlm not authenticated — run: nlm login"
else
  miss "nlm — install: uv tool install notebooklm-mcp-cli ; then: nlm setup add claude-code"
fi

echo "Loki Mode (autonomous build):"
if have loki; then
  ok "loki present"
  loki doctor >/dev/null 2>&1 && ok "loki doctor OK" || warn "loki doctor reported issues — run: loki doctor"
else
  miss "loki — install: bun install -g loki-mode"
fi

echo "Browser testing (per-story UI test + competitor capture):"
have npx && ok "npx present (Playwright/CloakBrowser via harness 'npm install' + 'npm run serve')" \
         || warn "npx missing — needed to run the cartography harness / CloakBrowser"
curl -s -o /dev/null -m 2 http://127.0.0.1:9222/json/version 2>/dev/null \
  && ok "CloakBrowser CDP reachable on :9222" \
  || warn "CloakBrowser not serving on :9222 — start it with 'npm run serve' when needed"

echo "Consultant (optional second opinion):"
have codex && ok "codex present" || warn "codex — optional (npm i -g @openai/codex)"

echo "MCP servers configured (Claude Code):"
if have claude; then
  claude mcp list 2>/dev/null || warn "could not list MCP servers (run 'claude mcp list' manually)"
else
  warn "claude CLI not found — in Cowork, check connectors via the connector UI instead"
fi

echo
echo "Note: this is a read-only check. See references/mcp-preflight.md for remediation steps."
