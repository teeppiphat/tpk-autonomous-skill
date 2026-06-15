# NotebookLM Deep Research & Expert Notebooks

Two uses of NotebookLM in this pipeline: (1) **fill researchable gaps** with deep research, and (2) build
**expert notebooks** (phase 2) that later phases consult. Both run through `notebooklm-mcp` (the unified
`notebooklm-mcp-cli` package: `nlm` CLI + `notebooklm-mcp` server). Preflight first (`mcp-preflight.md`).

## When to use research vs. ask the user

Classify each gap:
- **Researchable** (public/external): market size, a competitor's features/pricing, industry norms, regulations,
  public reviews/quotes. → Deep research below.
- **Not researchable** (internal/decision/customer-specific): target numbers, sell price, headcount, brand choices,
  a partner's private forms/formulas, credentials. → Add to `pipeline/<NN>-<phase>/NEEDS-INPUT.md`
  (template `assets/needs-input-template.md`) and ask the user.

Unsure? Try one scoped query/search. If it can't be sourced publicly, treat it as needs-user-input.

## Deep research workflow (fill a gap)

1. **Create / pick a notebook** for the topic: `notebook_create` (MCP) or `nlm notebook create "<topic>"`.
2. **Run deep research and import sources:** `research_start` then `research_status` (MCP), or
   `nlm research start "<question>"`. Import the top sources into the notebook. Natural-language form:
   *"Do deep research on `<question>` and import the top 10 sources."*
3. **Add any known-good sources** you already have: `source_add` (url / text / drive / file).
4. **Query for the answer with citations:** `notebook_query` (single expert) or `cross_notebook_query` (across
   several experts). Persisted to the NotebookLM web UI automatically.
5. **Fold findings into the phase document**, citing source titles, and mark confidence (🔵/🟡/❌). Update
   `state.json` and reduce the gap count.

## Building an expert notebook (phase 2)

Each notebook = one non-overlapping topic, configured to answer **only from its sources, with citations**.

1. `notebook_create` per topic (e.g. one per major competitor, one for market/industry, one for the design
   partner's workflow).
2. `source_add` the relevant phase-1 research files into that notebook.
3. `chat_configure` with this persona template:

```
You are the product expert for "<system>" by "<company>". Answer ONLY from sources.
When asked about features, give: (1) what it does, (2) how it's implemented based on public info,
(3) user complaints if any, (4) "I don't know" if not in sources.
Never speculate beyond sources. Always cite source titles.
```

4. Verify with a `notebook_query` ("what are the key features and known complaints?").
5. Record `{id, topic}` in `state.json.notebooks` and `pipeline/02-expert-notebooks/notebooks.md`.

## Consulting experts in later phases

During brainstorm/analysis (phase 3) and design questions (4.5), query the relevant expert notebook(s) instead of
guessing, and bring a second opinion from a consultant model (Codex/Gemini) where useful. Always carry the citations
back into the document so claims stay traceable.

## Notes & limits

- 35 MCP tools — disable the server when not in use to save context (`@notebooklm-mcp` in Claude Code).
- Free tier ~50 queries/day; cookies expire every few weeks (`nlm login` to refresh; auto-refresh if a profile is saved).
- Studio extras (`studio_create`) can produce an audio/slide summary of a notebook for sharing with the team.
