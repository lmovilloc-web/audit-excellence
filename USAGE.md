# Usage manual

Three slash commands, three use cases. Everything else is automatic.

## Quick reference

| Command | When to use | Cost | Wall-clock |
|---|---|---|---|
| `/audit` | Pre-launch, weekly, post-incident | ~10k tokens | 5–15 min |
| `/audit-quick` | Pre-commit sanity check | ~4k tokens | 2–3 min |
| `/diagnose <symptom>` | Live incident triage | ~3k tokens | as long as needed |

---

## `/audit` — full audit

Runs all six sub-auditors in parallel. Returns one severity-sorted table.

```
/audit
```

Optional arguments narrow the scope:

```
/audit only config
/audit skip smoke
/audit focus on Supabase
```

### What you'll see

1. **Stack detection** — one-line summary ("React + Vite + Supabase on Cloudflare Pages").
2. **Dispatch** — six sub-agents launched in parallel.
3. **Per-section findings** — each sub-agent posts its punch list as it finishes.
4. **Final table** — Section × Status × Findings × Action.

### Example output

```
## Audit run — 2026-05-18 on ReadyApp
Stack: React 19 + Vite + Supabase + Cloudflare Pages
Duration: 7 min

| Section | Status | Findings | Action |
|---|---|---|---|
| Config | 🔴 | 1 critical | Trim env var in CF Pages |
| Browser | 🟡 | 1 advisory | localStorage SRS state needs DB backup |
| Observability | 🟢 | 0 | — |
| Smoke | 🔴 | 2 missing tests | Add invite + delete-teacher specs |
| Runbooks | 🟢 | 0 | — |

### Critical findings
1. Trailing space in VITE_SUPABASE_URL detected.
   Evidence: cat -e shows 'co \r$'
   Fix: Cloudflare dashboard → Pages → env vars → trim value → redeploy
...
```

### When to run

- **Pre-launch** — before opening to real users.
- **Weekly** — config drift catches up with you fast.
- **Post-incident** — find latent variants of the bug that just hit you.
- **Pre-deploy of risky change** — schema migration, auth changes, new third-party service.

---

## `/audit-quick` — fast subset

Runs only `config-auditor` and `observability-auditor`. Skips browser, smoke, runbooks. Good for "I just changed an env var, did I break anything?"

```
/audit-quick
```

Same output format as `/audit`, just shorter and faster.

### When to run

- Right after editing a Cloudflare/Vercel env var.
- After adding a new edge function (verify error logging is wired).
- Before every push to main if you want CI-like local gating.

---

## `/diagnose` — live incident triage

For when a user reports an error **right now**. Enforces DevTools-first protocol; refuses to speculate.

```
/diagnose Cynthia gets "Failed to fetch" when she clicks Bake Exercises
```

### How it walks you through it

1. **First response:** asks you for a DevTools Console + Network screenshot. No exceptions. If the user is on iPad/Safari, asks them to reproduce on desktop.
2. **Classifies the failure** from the console message (CSP block, CORS, server error, JS bug).
3. **Confirms with SQL** — queries `edge_function_errors` and `client_errors` for the timestamp window.
4. **Inspects the failing URL** for `%20`, `undefined`, typos.
5. **Reproduces** in the same conditions before recommending a fix.
6. **Asks before applying** any destructive fix.

### Anti-patterns it refuses

- "Just roll back the last deploy" — diagnose first.
- "Let me curl it" — curl ignores CSP, useless for browser-only bugs.
- "Apply done" — verifies migrations with SQL before continuing.
- "I'm pretty sure it's X" — not until the evidence says so.

### Use cases

- A user reports a fetch error.
- An edge function returns 500 with no clear cause.
- Something used to work, doesn't now.
- The CI smoke test passes but real users see errors.

---

## Activation

The suite activates automatically when:

1. The files exist in your project's `.claude/agents/`, `.claude/skills/`, `.claude/commands/` (the install step).
2. You **start a new Claude Code session** in that project directory (existing sessions don't hot-reload agent definitions).

In the new session, type `/help` and you should see the three audit commands. Type `/audit` to start.

If `/audit` isn't recognized:
- Confirm `.claude/commands/audit.md` exists in the project root.
- Restart Claude Code (`exit` then re-open).
- Run `claude --version` — agent/skill loading was tightened in newer versions.

---

## Reading the results

### `🔴` Critical

Production is broken or imminently will be. Fix immediately.

### `🟡` Advisory

Latent risk, not currently causing harm. Schedule a fix.

### `🟢` Pass

Verified clean with evidence. Re-check in 90 days.

Findings without evidence are rejected by the orchestrator — if you see "Looks fine", that's a bug in the sub-agent and worth a PR back to this repo.

---

## Common workflows

### Pre-launch checklist

```
/audit
```

Address all 🔴 first. Triage 🟡 into "fix now" vs "after launch". Save the report — it's your launch documentation.

### Post-incident

```
/diagnose <symptom>
# ... resolve ...
/audit only runbook-keeper
```

The second call ensures the new runbook captures what you learned.

### Quarterly review

```
/audit
```

Full audit. Compare findings to last quarter's report. If a category went from 🟢 to 🟡, investigate the drift.

### Onboarding a new engineer

Have them run `/audit` on day 1. The output is a project tour: stack, infra, known risks, what's monitored, what's not.

---

## Cost

Roughly **$0.30 per full audit run** at current Claude Opus pricing. Less than the cost of one incident.

Run it often.

---

## Troubleshooting

### "/audit isn't a command"

The slash commands weren't loaded. Check:
1. `ls .claude/commands/` shows `audit.md`, `audit-quick.md`, `diagnose.md`.
2. You're in the project root (not a subfolder) when running Claude Code.
3. Restart Claude Code.

### "Agent audit-orchestrator not found"

The agent files weren't loaded. Check:
1. `ls .claude/agents/` shows all seven `.md` files.
2. Each has YAML frontmatter starting with `---`.
3. Restart Claude Code.

### "An audit step failed"

Each sub-agent is independent. A failure in one doesn't stop the others. Re-run with `/audit only <category>` to retry just that section.

### "The findings are wrong / hallucinated"

The orchestrator requires evidence (SQL output, grep output, file contents) for every finding. If a sub-agent returns a hallucinated finding, it's a regression in that sub-agent's prompt — file an issue or PR.
