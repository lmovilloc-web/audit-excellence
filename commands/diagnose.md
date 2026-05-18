---
description: Triage a live incident with DevTools-first protocol. Refuses speculation, demands evidence, prevents anchoring on recent deploys.
---

Launch the diagnostic-helper agent. It will:

1. Refuse to speculate until you provide a DevTools console + Network screenshot.
2. Classify the failure (CSP block, CORS, server error, JS bug).
3. Confirm with a SQL query against your error tables.
4. Inspect the actual failing URL for `%20`, `undefined`, or other malformations.
5. Reproduce in the user's actual environment before suggesting a fix.

If the user can't access DevTools (iPad Safari etc.), it falls back to SQL-only triage but warns about the lower diagnostic confidence.

$ARGUMENTS

---

Call the diagnostic-helper agent. Pass the user's description of the incident (the $ARGUMENTS string) so it has context for the triage.
