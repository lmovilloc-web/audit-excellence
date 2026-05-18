# Changelog

## [0.1.0] — 2026-05-18 — Initial release

Born from the Ready2 trailing-space CSP outage. Six agents, five skills, three slash commands.

### Agents
- audit-orchestrator
- config-auditor
- browser-auditor
- observability-auditor
- smoke-auditor
- diagnostic-helper
- runbook-keeper

### Skills
- trim-env-vars
- audit-csp
- audit-rls-silent-fail
- diagnose-fetch-fail
- verify-migration

### Commands
- /audit
- /audit-quick
- /diagnose

### Founding incidents
- 2026-05-18: Trailing space in `VITE_SUPABASE_URL` (Cloudflare Pages) blocked all edge-function calls via CSP. Code review missed it; deploy config was out of audit scope.
- 2026-05-17: `www.ready2.app` custom domain binding silently removed from Cloudflare Pages.
- 2026-05-05: `/assets/*` cache poisoning, 8h outage.
- 2026-05-06: Mass `UPDATE profiles SET role = ...` without WHERE locked out the operator.
