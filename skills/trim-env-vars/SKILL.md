---
name: trim-env-vars
description: Scan a codebase for env-var reads (import.meta.env, process.env, Deno.env.get) and verify each one trims whitespace. Catches the trailing-space bug that broke our prod for 2 hours. Stack-agnostic.
---

# Skill: trim-env-vars

## When to use

- During config audit.
- After noticing "Failed to fetch" or CSP violations with `%20` in URLs.
- Pre-launch sanity check.

## How to run

1. **Find every env-var read site.** Use:
   ```bash
   grep -rn "import\.meta\.env\.\|process\.env\.\|Deno\.env\.get(" src/ supabase/ app/ 2>/dev/null \
     | grep -v "node_modules\|\.test\.\|\.spec\." | head -80
   ```

2. **For each match, inspect 2 lines.** Look at the line containing the env read and the next line. The value should either:
   - Be `.trim()`-ed before use, OR
   - Be assigned to a constant that was already trimmed at module-level (one central place), OR
   - Be only compared (not concatenated into a URL or used as a fetch destination), in which case whitespace is harmless.

3. **Flag any that build URLs from un-trimmed values.** Specifically search for `\`\${...}\${import.meta.env...}\`` patterns that interpolate without `.trim()`.

4. **Verify the fix.** After patching, build the project and re-run the grep — every match should now route through a trimmed source.

## The bug we're preventing

```ts
// BAD — silently appends trailing whitespace
const API = import.meta.env.VITE_API_URL
fetch(`${API}/users`)  // → "https://api.example.com /users" → "%20" → CSP block

// GOOD
const API = (import.meta.env.VITE_API_URL ?? '').trim()
```

## Output

Return a punch list:

```
Env-var read sites: 12
Trimmed (or safe): 11
Vulnerable: 1
  src/lib/api.ts:8 — VITE_API_URL interpolated without .trim()
  Fix: const API = (import.meta.env.VITE_API_URL ?? '').trim()
```

## Token budget

This skill itself is ~250 tokens. The grep output is bounded by `head -80`. Total context cost per invocation: under 1k tokens.
