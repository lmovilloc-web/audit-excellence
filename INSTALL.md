# Install

Drop into any project. Three steps.

## 1. Clone or download

```bash
git clone --depth 1 https://github.com/<you>/audit-excellence /tmp/audit-excellence
```

(Replace `<you>` with the actual GitHub org/user once you publish.)

## 2. Copy into your project's `.claude/`

```bash
cd /path/to/your-project
mkdir -p .claude/agents .claude/skills .claude/commands

cp -r /tmp/audit-excellence/agents/* .claude/agents/
cp -r /tmp/audit-excellence/skills/* .claude/skills/
cp -r /tmp/audit-excellence/commands/* .claude/commands/
```

## 3. Reload Claude Code

In your Claude Code session:
- `/help` should now show `/audit`, `/audit-quick`, `/diagnose` in the list.
- Open the Agents menu and you should see all six audit agents.

## Run your first audit

```
/audit
```

It will detect your stack and dispatch all six sub-auditors. Expect 5–15 minutes wall-clock and a punch list of findings.

## Optional: gitignore the copy

If you don't want the agent suite tracked in your repo:

```
echo ".claude/agents/audit-*.md" >> .gitignore
echo ".claude/skills/audit-*/"   >> .gitignore
echo ".claude/skills/trim-env-vars/" >> .gitignore
echo ".claude/skills/diagnose-fetch-fail/" >> .gitignore
echo ".claude/skills/verify-migration/" >> .gitignore
echo ".claude/commands/audit*.md" >> .gitignore
echo ".claude/commands/diagnose.md" >> .gitignore
```

Or keep them tracked so the whole team has them — preferred for shared infra.

## Stack-specific extras

The skills handle Supabase, Cloudflare Pages, and Vercel out of the box. If you use a different stack, see `examples/` for templates and PR yours back.

## Uninstall

```bash
rm .claude/agents/audit-*.md
rm -rf .claude/skills/{trim-env-vars,audit-csp,audit-rls-silent-fail,diagnose-fetch-fail,verify-migration}
rm .claude/commands/{audit.md,audit-quick.md,diagnose.md}
```
