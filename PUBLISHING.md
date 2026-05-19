# Publishing to GitHub — step by step

How to put this repo on GitHub so anyone (or future-you on another project) can install it.

## Option A — fastest (with `gh` CLI)

If you have GitHub CLI installed (`gh --version` to check):

```bash
cd /Users/lukasmovillo/audit-excellence

# Creates the repo on GitHub, sets origin remote, pushes main.
# --public makes it discoverable; use --private to keep it for yourself.
gh repo create audit-excellence \
  --public \
  --description "Drop-in Claude Code audit agents — catches the bugs code-only audits miss" \
  --source=. \
  --remote=origin \
  --push
```

Done. Open the URL `gh` prints to see your repo live.

If `gh` is not installed: `brew install gh && gh auth login` (Mac) or follow [cli.github.com](https://cli.github.com).

## Option B — manual (web UI + git CLI)

If you prefer the GitHub web UI:

1. Go to https://github.com/new
2. **Repository name:** `audit-excellence`
3. **Description:** `Drop-in Claude Code audit agents — catches the bugs code-only audits miss`
4. **Visibility:** Public (or Private — works either way)
5. **DO NOT** check "Add a README" / "Add .gitignore" / "Add license" — we already have these locally and the import will collide.
6. Click **Create repository**.

GitHub will show you a "push existing repo" snippet. Adapted for our case:

```bash
cd /Users/lukasmovillo/audit-excellence

# Use SSH (preferred — no password prompts):
git remote add origin git@github.com:lmovilloc-web/audit-excellence.git

# OR HTTPS (asks for a PAT on push):
# git remote add origin https://github.com/lmovilloc-web/audit-excellence.git

git push -u origin main
```


## Verifying it worked

```bash
git -C /Users/lukasmovillo/audit-excellence remote -v
# Should show: origin git@github.com:<user>/audit-excellence.git (fetch + push)

git -C /Users/lukasmovillo/audit-excellence log origin/main -1
# Should match your local HEAD.
```

Open the GitHub URL — you should see all 22 files.

## After publishing — quick polish

### 1. Add topics for discoverability

On the repo's GitHub page → ⚙️ next to "About" → Topics:

```
claude-code
claude-agents
audit
devops
observability
supabase
cloudflare-pages
production-readiness
```

These make the repo show up in GitHub topic searches.

### 2. Pin to your profile

Profile → Customize your pins → select `audit-excellence`. Free marketing for any visitor.

### 3. Update README install link

The README currently says `https://github.com/lmovilloc-web/audit-excellence`. Replace `<you>` with your actual username so copy-paste installs Just Work:

```bash
cd /Users/lukasmovillo/audit-excellence
sed -i '' 's|https://github.com/lmovilloc-web/audit-excellence|https://github.com/lmovilloc-web/audit-excellence|g' README.md INSTALL.md
git add README.md INSTALL.md
git commit -m "docs: replace placeholder with actual repo URL"
git push
```

### 4. Optional — release tag

Once published, tag v0.1.0:

```bash
git -C /Users/lukasmovillo/audit-excellence tag -a v0.1.0 -m "v0.1.0 — initial release"
git -C /Users/lukasmovillo/audit-excellence push origin v0.1.0
```

Then on GitHub: Releases → Draft a new release → pick tag v0.1.0 → publish. People can `git clone --depth 1 --branch v0.1.0 ...` for a stable version.

### 5. Optional — install one-liner

Add to your README a curl-based installer. Create `install.sh` at the repo root:

```bash
cat > /Users/lukasmovillo/audit-excellence/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO="https://github.com/lmovilloc-web/audit-excellence"
TMP=$(mktemp -d)
git clone --depth 1 "$REPO" "$TMP"
mkdir -p .claude/agents .claude/skills .claude/commands
cp -r "$TMP/agents/"* .claude/agents/
cp -r "$TMP/skills/"* .claude/skills/
cp -r "$TMP/commands/"* .claude/commands/
rm -rf "$TMP"
echo "✅ Installed. Restart Claude Code and try /audit"
EOF
chmod +x /Users/lukasmovillo/audit-excellence/install.sh
```

Then users can:

```bash
curl -L https://raw.githubusercontent.com/lmovilloc-web/audit-excellence/main/install.sh | bash
```

## Authentication notes

### SSH (recommended)

If you haven't set up SSH for GitHub yet:

```bash
ssh-keygen -t ed25519 -C "you@email.com"
# accept defaults, no passphrase if you prefer

cat ~/.ssh/id_ed25519.pub | pbcopy
# paste at https://github.com/settings/keys → New SSH key

ssh -T git@github.com
# should say "Hi <user>! You've successfully authenticated"
```

### HTTPS + PAT

If you prefer HTTPS, GitHub doesn't accept passwords anymore. You need a Personal Access Token:

1. https://github.com/settings/tokens?type=beta → Generate new token → Fine-grained.
2. Permissions: **Contents: Read/Write** on the specific repo.
3. Copy the token (starts with `github_pat_`).
4. When `git push` prompts for password, paste the token.

Cache it so you don't paste every time:

```bash
git config --global credential.helper osxkeychain  # Mac
```

## Updating the public repo later

After making local changes (new agent, new skill, etc.):

```bash
cd /Users/lukasmovillo/audit-excellence
git add .
git commit -m "feat: add <thing>"
git push
```

Bump the version in `CHANGELOG.md` for substantive changes.

## Promoting it

Once published, share:

- **r/ClaudeAI** subreddit — the audience uses Claude Code daily.
- **Hacker News Show HN** — "Show HN: Audit agents for Claude Code, born from a real outage".
- **Twitter/X** — tag @AnthropicAI, screenshot the audit output.
- **Anthropic Discord** — `#claude-code` channel.

A real-incident origin story is the hook — "this caught a CSP bug we lost 2 hours to" lands harder than "yet another linter".
