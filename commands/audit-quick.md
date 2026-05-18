---
description: Quick audit — config + observability only. ~3 min, ~4k tokens. Good for pre-commit sanity check.
---

Launch the audit-orchestrator with a narrowed scope: only config-auditor and observability-auditor.

Use this when:
- You just changed an env var and want to confirm no whitespace crept in.
- You added a new edge function and want to confirm error logging is wired.
- You want a pre-deploy sanity check without paying for the full audit.

For a full audit, use `/audit` instead.

$ARGUMENTS

---

Call the audit-orchestrator agent with arguments "scope: config + observability only".
