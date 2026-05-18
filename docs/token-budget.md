# Token budget

How we keep the audit suite cheap.

## Per-component cost

| Component | Prompt tokens | When it loads |
|---|---|---|
| audit-orchestrator | ~300 | Every `/audit` |
| config-auditor | ~400 | When orchestrator dispatches |
| browser-auditor | ~400 | When orchestrator dispatches |
| observability-auditor | ~400 | When orchestrator dispatches |
| smoke-auditor | ~350 | When orchestrator dispatches |
| diagnostic-helper | ~450 | Only during incident triage |
| runbook-keeper | ~400 | When orchestrator dispatches |
| trim-env-vars (skill) | ~250 | Only when invoked |
| audit-csp (skill) | ~250 | Only when invoked |
| audit-rls-silent-fail (skill) | ~250 | Only when invoked |
| diagnose-fetch-fail (skill) | ~400 | Only when invoked |
| verify-migration (skill) | ~300 | Only when invoked |

## Typical run costs

### `/audit` (full)
- Orchestrator: 300
- 5 sub-agents (excludes diagnostic-helper, only fires for incidents): 1,950
- 2–3 skills loaded by sub-agents: 500–750
- **Total prompt overhead: ~3k tokens.**

Plus the actual content of the audit (the grep results, SQL outputs, file reads) which varies by project size but typically 3–7k tokens.

**Grand total per audit run: ~6–10k tokens.**

### `/audit-quick`
- Orchestrator + 2 sub-agents + 1 skill = **~1.5k prompt overhead.**

### `/diagnose`
- Diagnostic helper + diagnose-fetch-fail skill = **~850 prompt overhead.**

## Compare to a mega-prompt approach

If you put every check into a single agent's system prompt:
- ~10k tokens **just to load the prompt** before any audit work.
- Loaded on every single conversation turn after invocation.
- Hard to keep coherent — long prompts degrade in quality.

Our split: **~3k for the same coverage**, and only loads what's relevant.

## How to keep costs low when extending

1. **Sub-agent prompts under 500 tokens.** If yours grows past that, split it.
2. **Skills are where the long instructions live.** Skills only load on invocation.
3. **Never put example output in a system prompt.** Output formats are written as templates the agent fills in, not as long examples.
4. **Reference, don't duplicate.** If two agents need the same protocol, put it in a skill and have both reference it.
5. **No prose explanations in prompts.** The agent doesn't need to know *why* the audit matters; it needs to know *what* to do.

## When the cost is worth it

A single production incident in our experience costs:
- 2–4 hours of engineer time to diagnose,
- 1–8 hours of customer pain,
- $X in lost trust.

A full `/audit` run costs **~$0.30** at current Claude pricing. The math is trivial.

Run it weekly. Run it before every launch. Run it after every incident.
