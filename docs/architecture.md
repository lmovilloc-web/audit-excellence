# Architecture

## Why six sub-agents instead of one mega-agent

A single agent that "audits everything" suffers from three problems:

1. **Long prompt** — the model has to load every check into context every time. 10k tokens of system prompt before any work happens.
2. **No parallelism** — a single agent runs checks serially. Six parallel sub-agents are 4–6× faster wall-clock.
3. **Hard to extend** — adding a new check means editing one giant prompt, risking regression in unrelated checks.

Our design: one short orchestrator + six focused sub-agents + on-demand skills.

## Component responsibilities

```
audit-orchestrator (~300 tokens)
  ├── Detects stack (reads config files)
  ├── Picks which sub-agents to dispatch
  ├── Dispatches in parallel (single message, multiple Agent calls)
  ├── Collates findings into one severity-sorted table
  └── Reports back to user

config-auditor (~400 tokens)
  ├── Local .env files (cat -e)
  ├── Code-side env-var hygiene
  ├── Deploy-platform env vars (user-action checklist)
  ├── Secrets / vault
  ├── DNS, custom domains
  ├── _headers, _redirects, _worker.js
  └── Build/runtime config parity

browser-auditor (~400 tokens)
  ├── CSP completeness
  ├── localStorage inventory + ITP exposure
  ├── Service worker behavior
  ├── Cookie flags
  ├── Capacitor / mobile WebView
  └── CORS round-trip

observability-auditor (~400 tokens)
  ├── Error table existence
  ├── RLS on error tables (INSERT must allow auth users)
  ├── ErrorBoundary coverage
  ├── Global error/rejection handlers
  ├── Edge function error capture
  ├── Step-tagged client errors
  └── Alerting

smoke-auditor (~350 tokens)
  ├── Existing spec inventory
  ├── Moneymaker identification
  ├── Coverage matrix
  └── CI integration

diagnostic-helper (~450 tokens)
  ├── DevTools-first protocol
  ├── Console-error classification
  ├── URL malformation inspection (%20, undefined)
  ├── SQL-side confirmation
  └── Anti-patterns refusal

runbook-keeper (~400 tokens)
  ├── Inventory + staleness
  ├── Required runbook coverage
  ├── Recent incident coverage
  └── Authoring template

Skills (load on-demand, ~250 tokens each)
  ├── trim-env-vars
  ├── audit-csp
  ├── audit-rls-silent-fail
  ├── diagnose-fetch-fail
  └── verify-migration
```

## How dispatch works

The orchestrator uses `Agent` tool calls. To run all six in parallel:

```
Agent(audit-orchestrator) →
  one response containing six Agent calls →
    each sub-auditor runs concurrently →
      each returns a punch list →
        orchestrator collates →
          user gets one table
```

This relies on Claude Code's ability to issue multiple tool calls in a single response (which is standard).

## Why skills (not just more agents)

Skills are **stack-specific recipes** that load only when invoked. An audit may dispatch the `config-auditor` sub-agent, which then calls the `trim-env-vars` skill — the skill's full instructions only load if needed. This keeps the audit start-up cheap.

Compare:

- **One mega-agent**: ~10k tokens loaded on first turn regardless of stack.
- **Sub-agents + skills**: ~3k tokens for orchestrator + sub-agent prompts. Skills load only when a check needs them.

For a typical audit run, this cuts cold-start cost by ~70%.

## Adding a new audit category

1. Write a new sub-agent in `agents/<name>-auditor.md`. Keep it under 500 tokens.
2. If it needs a reusable check, add a skill in `skills/<check-name>/SKILL.md`.
3. Add a row to `audit-orchestrator.md`'s "Available sub-auditors" table.
4. Bump the README version.

That's it. No editing existing agents. No regression risk.

## Adding a new stack

If your stack isn't Supabase / Cloudflare Pages / Vercel:

1. Look at `examples/<existing-stack>/` for reference.
2. Add stack detection logic to `audit-orchestrator.md`'s detect-the-stack step.
3. Add stack-specific recipes to the relevant skills.
4. PR back.

## Failure modes we explicitly avoid

- **Recursive audits.** Sub-agents don't trigger other sub-agents. If a finding suggests another category needs auditing, it's logged as a finding, not a new dispatch. Prevents runaway token spend.
- **Re-running on the same data.** Each agent's output is the final word for its section. Orchestrator doesn't second-guess.
- **Silent skips.** If a sub-agent fails or times out, the orchestrator reports the failure prominently. Better to have a known gap than a false green.
