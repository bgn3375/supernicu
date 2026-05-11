#!/bin/bash
# SuperNicu pre-commit hook: verifică că SPEC-urile există pentru paginile modificate
# Acest hook avertizează (nu blochează) dacă se modifică o pagină fără SPEC

set -e

# Caută fișiere frontend modificate (pagini)
CHANGED_PAGES=$(git diff --cached --name-only --diff-filter=ACM | grep -E "app/.*page\.(tsx|ts)$" || true)

if [ -z "$CHANGED_PAGES" ]; then
    exit 0
fi

echo "📋 SuperNicu: Verificare SPEC-uri pentru paginile modificate..."

MISSING_SPECS=0
for page in $CHANGED_PAGES; do
    # Extrage numele paginii din path
    PAGE_NAME=$(echo "$page" | sed 's|.*/\([^/]*\)/page\.tsx\?$|\1|')

    # Caută SPEC corespunzător
    SPEC_FILE=$(find . -name "SPEC-${PAGE_NAME}*.md" -o -name "SPEC_${PAGE_NAME}*.md" 2>/dev/null | head -1)

    if [ -z "$SPEC_FILE" ]; then
        echo "  ⚠️  Pagina '$PAGE_NAME' modificată fără SPEC (${page})"
        MISSING_SPECS=$((MISSING_SPECS + 1))
    else
        echo "  ✓ ${PAGE_NAME} → ${SPEC_FILE}"
    fi
done

if [ $MISSING_SPECS -gt 0 ]; then
    echo ""
    echo "⚠️  ${MISSING_SPECS} pagini modificate fără SPEC. Pipeline SuperNicu necesită SPEC aprobat."
    echo "   Continuă commit-ul, dar implementarea poate fi incompletă."
fi

exit 0
