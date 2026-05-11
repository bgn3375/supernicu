#!/bin/bash
# Sincronizează skill-ul SuperNicu din repo la ~/.claude/skills/ după modificări
# Rulează automat după commit-uri pe SKILL.md
# Instalare: cp hooks/sync-skill.sh .git/hooks/post-commit && chmod +x .git/hooks/post-commit

set -e

REPO_SKILL="$(git rev-parse --show-toplevel)/skills/supernicu"
USER_SKILL="$HOME/.claude/skills/supernicu"

if [ ! -d "$REPO_SKILL" ]; then
    exit 0
fi

# Verifică dacă SKILL.md s-a modificat în ultimul commit
if git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -q "skills/supernicu/"; then
    echo "🔄 SuperNicu skill modificat — sincronizez la ~/.claude/skills/supernicu/"
    rsync -av --delete "$REPO_SKILL/" "$USER_SKILL/" > /dev/null
    echo "  ✓ Sync complete"
fi
