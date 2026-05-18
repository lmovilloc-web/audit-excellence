---
name: diagnose-fetch-fail
description: Diagnostic protocol for a live "Failed to fetch" or fetch network error in a user's browser. Enforces DevTools-first, prevents anchoring on recent deploys, and avoids using curl for browser-only bugs. Use immediately when a user reports a network error.
---

# Skill: diagnose-fetch-fail

## The rule

**Step 1 is always: get a DevTools console + Network screenshot.** No exceptions, no speculation, no rollbacks until you have evidence.

## The protocol

### Step 1 — Request screenshots

If the user hasn't shared one, respond with:

> Before I diagnose, please share:
> 1. The browser DevTools Console tab (F12 → Console). Reproduce the error and screenshot any red lines.
> 2. The Network tab. Reproduce again and screenshot the failing request row.

If they're on iPad/Safari mobile (no DevTools), ask them to reproduce on a desktop browser. If they can't, fall back to Step 4 (server-side SQL).

### Step 2 — Read the console

Map what you see:

| Console message | Likely cause |
|---|---|
| `... violates Content Security Policy directive "connect-src"` | The fetch URL host isn't in CSP. Inspect the URL — `%20` suggests trailing whitespace in env var. |
| `Failed to fetch` with no other message | CSP block OR network drop. Check Network tab for a corresponding (failed) row. |
| `CORS policy: No 'Access-Control-Allow-Origin'` | Server CORS issue. |
| `Refused to connect to '...'` | CSP block (explicit). |
| `TypeError: NetworkError when attempting to fetch` (Firefox) | Same as "Failed to fetch". |
| Stack trace from JS | Not a network issue — JS error. Different diagnosis. |

### Step 3 — Inspect the URL

In the Network tab, click the failing row. Read the URL carefully. Look for:

- `%20` in the host → trailing whitespace in an env var (run the [trim-env-vars](../trim-env-vars/SKILL.md) skill).
- `undefined` in the URL → env var not set at build time.
- Wrong host or typo.
- Mixed `http://` / `https://`.

### Step 4 — Verify server-side

Run a quick SQL check:

```sql
SELECT count(*) FROM edge_function_errors
WHERE function_name = '<the function>'
  AND created_at > now() - interval '15 minutes';
```

- **0 rows** → The request never reached the server. Confirms a browser-side block (CSP, CORS, DNS, network).
- **Rows present** → The function ran and threw. Diagnose server-side.

### Step 5 — Reproduce — but in the right environment

If the bug is browser-only, **do not use curl** to verify. Curl ignores CSP. It will succeed when the browser fails. Reproduce in:
- The same browser (Chrome / Safari / Firefox).
- The same logged-in user state.
- The same data (some bugs only fire with specific payloads).

### Step 6 — Fix

Match the root cause to a fix:

- Trailing whitespace in env var → `.trim()` in client, fix the dashboard env var.
- Missing CSP entry → add to `_headers` or equivalent.
- Wrong host → fix the env var.
- CORS → server-side fix (add origin to allowlist).
- 500 from function → server-side diagnosis (read the function's catch path).

## Anti-patterns — REFUSE these

- "It started after my last deploy, let me roll back." ← Anchoring. Diagnose first.
- "Let me curl it to see." ← Curl ignores CSP and many browser policies. Reproduce in a browser.
- "Apply done." ← Verify with a SQL query before continuing.
- "I'm pretty sure it's X." ← Not until the evidence says so.

## Output format

```
Diagnosis: <one sentence>
Evidence: <quoted from DevTools / SQL>
Root cause: <one sentence>
Fix: <specific action — file, line, command>
Reproduce after fix: <how to confirm>
```

End with: "Should I apply the fix or do you want to handle it?"
