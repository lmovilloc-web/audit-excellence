---
name: audit-csp
description: Verify every fetch destination in the codebase is allowed by the live site's Content Security Policy. Catches the "Failed to fetch" caused by an unlisted host in connect-src. Works for Cloudflare Pages _headers, Vercel headers config, and inline <meta> CSP.
---

# Skill: audit-csp

## When to use

- During config audit.
- Before adding a new third-party service (Stripe, Sentry, Mixpanel).
- After a "Failed to fetch" report.

## How to run

1. **Fetch the live CSP.**
   ```bash
   curl -sI https://<your-domain>/ | grep -i content-security-policy
   ```
   If empty, the site has no CSP — that's a security issue but won't cause "Failed to fetch".

2. **Find the CSP source in the repo.** It can live in:
   - `public/_headers` or `dist/_headers` (Cloudflare Pages)
   - `vercel.json` → `headers`
   - `next.config.js` → `headers()`
   - `<meta http-equiv="Content-Security-Policy">` in `index.html`
   - A middleware / `_worker.js`

3. **Enumerate every fetch destination in code.**
   ```bash
   grep -rEn "fetch\(|new (WebSocket|EventSource)\(|axios\.|XMLHttpRequest" src/ \
     | grep -oE "https?://[a-zA-Z0-9.-]+" | sort -u
   ```

4. **Cross-check.** For each destination URL's host, confirm it matches a `connect-src` entry. Wildcards like `*.supabase.co` match any subdomain.

5. **Flag mismatches.** Each unmatched host is a future "Failed to fetch" once that code path is exercised.

## Common destinations to check

- Supabase: `https://*.supabase.co`, `wss://*.supabase.co`
- OpenAI: `https://api.openai.com`
- Resend: `https://api.resend.com`
- Stripe: `https://api.stripe.com`, `https://js.stripe.com`
- Cloudflare: `https://*.cloudflareinsights.com`

## Output

```
CSP audit
Live policy: connect-src 'self' https://*.supabase.co https://api.openai.com ...

Fetch destinations in code:
  https://ifeukwdfkwuvfbhadzzy.supabase.co ✅
  https://api.openai.com ✅
  https://hooks.zapier.com 🔴 NOT in CSP

Fix: add `https://hooks.zapier.com` to connect-src in public/_headers
```

## The bug we're preventing

A new fetch to a third-party API merged silently, the CSP wasn't updated, and the call fails with "Failed to fetch" in the browser console — but only when that specific code path runs (often days or weeks later).

## Token budget

~250 tokens prompt + bounded grep output. Total: under 1k.
