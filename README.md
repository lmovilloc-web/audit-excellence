# Audit Excellence

A drop-in Claude Code agent suite that runs production-grade audits on any web app — catches the bugs that code-only audits miss.

Born from a real outage: a trailing space in a Cloudflare Pages env var blocked all edge-function calls via CSP. The code was perfect. The deploy config wasn't. The team's existing audit reviewed code; the bug was invisible to it. This repo packages the lessons into reusable agents and skills.

## What it catches

- **Config bugs** invisible to code review: trailing whitespace in env vars, typos in secret names, missing DNS records.
- **Deploy-time gotchas**: CLI defaults flipping security flags (e.g. `verify_jwt`), migrations claimed applied but not applied.
- **Browser-only failures**: CSP violations, Safari ITP wiping localStorage, service worker stale state.
- **Silent failures**: RLS dropping writes without errors, smoke tests that pass while the moneymaker is broken.
- **Diagnostic anti-patterns**: anchoring on recent deploys, using curl for browser-only bugs, trusting "apply done" without verification.

## Architecture

```
audit-orchestrator         ← entry point, dispatches to sub-agents
├── config-auditor         ← env vars, secrets, DNS, _headers
├── browser-auditor        ← CSP, localStorage, ITP, service worker
├── observability-auditor  ← RLS on error tables, ErrorBoundary, alerts
├── smoke-auditor          ← defines critical-path E2E tests
├── diagnostic-helper      ← DevTools-first protocol for live incidents
└── runbook-keeper         ← runbook freshness, post-incident updates
```

Six focused sub-agents (~300 tokens each) + five on-demand skills + two slash commands. Total cold-start cost is ~3k tokens — the heavy lifting lives in skills that load only when invoked.

## Install

```bash
# In your project root:
git clone --depth 1 https://github.com/<you>/audit-excellence /tmp/audit-excellence
mkdir -p .claude/agents .claude/skills .claude/commands
cp -r /tmp/audit-excellence/agents/* .claude/agents/
cp -r /tmp/audit-excellence/skills/* .claude/skills/
cp -r /tmp/audit-excellence/commands/* .claude/commands/
rm -rf /tmp/audit-excellence
```

Then in Claude Code: `/audit` to run a full audit, `/diagnose` to triage a live incident.

## Stack support

Audit logic is stack-agnostic but skills include first-class recipes for:

- **Supabase** (RLS policies, edge functions, migrations, secrets)
- **Cloudflare Pages** (env vars, `_headers`, custom domains, CSP)
- **Vercel** (env vars per environment, headers in `vercel.json`)

The skills auto-detect your stack from `package.json` and project files. Stack-specific extensions are opt-in.

## Why six agents?

Specialization keeps prompts short and focused. Each sub-agent has one job, one mental model, and one set of evidence it must produce. The orchestrator only knows *what to run*, not *how* — that's the sub-agents' job. This means:

- Each invocation costs ~300 tokens of agent prompt + the skill it loads.
- Adding a new audit category = adding one sub-agent, no churn elsewhere.
- Sub-agents can run in parallel (orchestrator dispatches concurrently).

See [`docs/architecture.md`](docs/architecture.md) for the full reasoning.

## Token budget

Cold-start invocation of `/audit`: ~3k tokens (orchestrator + dispatch).
Per sub-agent fired: ~1k tokens (prompt + skill load).
Full 6-agent audit: ~10k tokens of prompts + the LLM's output.

This is roughly **one-tenth** the cost of a monolithic "audit everything" mega-prompt because skills load on demand and sub-agents have tight scope.

See [`docs/token-budget.md`](docs/token-budget.md).

## Use cases

- Pre-launch audit before going live.
- Post-incident audit to find latent variants of the bug that just hit you.
- Quarterly review (config drift, secrets rotation, runbook freshness).
- Onboarding a new engineer (they run the audit; output is the project tour).

## Credits

Born from incidents at [Ready2](https://ready2.app), an AI English learning platform built by Make It Easier SPA Chile. The 2026-05-18 trailing-space CSP outage is the founding incident.

## License

MIT — copy, modify, ship. No warranty.

## Contributing

Each real incident should add a new audit section or skill. PRs welcome — include the post-mortem of the incident that motivated the addition.
