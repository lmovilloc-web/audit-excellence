#!/usr/bin/env bash
# audit-excellence installer — drop the agent suite into a Claude Code project
# Usage (from the root of your target project):
#   curl -fsSL https://raw.githubusercontent.com/lmovilloc-web/audit-excellence/main/install.sh | bash

set -euo pipefail

REPO="https://github.com/lmovilloc-web/audit-excellence"
TMP=$(mktemp -d)

echo "→ Cloning audit-excellence..."
git clone --depth 1 --quiet "$REPO" "$TMP"

echo "→ Installing into $(pwd)/.claude/"
mkdir -p .claude/agents .claude/skills .claude/commands
cp -r "$TMP/agents/"*    .claude/agents/
cp -r "$TMP/skills/"*    .claude/skills/
cp -r "$TMP/commands/"*  .claude/commands/

rm -rf "$TMP"

echo ""
echo "✅ Installed. Files placed in .claude/{agents,skills,commands}/"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code in this directory."
echo "  2. Try /audit (full audit) or /diagnose (live incident triage)."
echo ""
echo "Manual: https://github.com/lmovilloc-web/audit-excellence/blob/main/USAGE.md"
