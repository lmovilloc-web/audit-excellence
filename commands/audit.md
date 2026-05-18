---
description: Run a full production audit using the audit-excellence agent suite. Catches config, browser, observability, deploy, and runbook gaps.
---

Launch the audit-orchestrator. It will:

1. Detect the stack (read package.json, supabase/config.toml, vercel.json, wrangler.toml).
2. Dispatch all six sub-auditors in parallel:
   - config-auditor
   - browser-auditor
   - observability-auditor
   - smoke-auditor
   - diagnostic-helper (only if there's an active incident)
   - runbook-keeper
3. Collate findings into a single severity-sorted table.

Estimated time: 5–15 minutes wall-clock. Estimated tokens: ~10k.

If you want a quicker subset, use `/audit-quick` (config + observability only, ~3 min, ~4k tokens).

If you're triaging a live incident, use `/diagnose` instead.

$ARGUMENTS

---

Call the audit-orchestrator agent with the user's arguments (if any) appended. If no arguments, run the default full-audit flow.
