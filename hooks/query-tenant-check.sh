#!/bin/bash
# SuperNicu — Query Tenant Check (G8 enforcement)
#
# Detectează queries pe entități indirect tenant-scoped care lipsesc
# de JOIN explicit pe parent.team_id. Vezi G8 în GUARDRAILS.md.
#
# IMPORTANT: Hook-ul flag-ează tipare suspecte, NU validează structura.
# Output-ul e rutat la review-bono care decide pass/fail.
#
# Mode: WARN-only (nu blochează commit-ul în primele 2-3 proiecte).
# Promovare la BLOCK: doar după validare empirică (false positives ≈ 0).
#
# Instalare: ln -sf ../../hooks/query-tenant-check.sh .git/hooks/pre-commit
# Sau: rulează manual înainte de PR review.

set -u

# === Configurare per-proiect ===
# Listează entitățile indirect tenant-scoped (fără team_id direct, dar legate de parent cu team_id).
# Sursa: Query Safety Matrix din Faza 2 ARCHITECT (SPEC-ul aprobat).
#
# Exemplu pentru P&L:
INDIRECT_ENTITIES=(
    "ExpenseAttachment"     # parent: Expense
    "ExpenseAuditLog"       # parent: Expense (când va fi creat)
    "InvoiceLine"           # parent: Invoice
    "BudgetCategory"        # parent: Budget
)

# Directoarele unde caută queries (.NET layout)
QUERY_DIRS=(
    "DomainServices/Queries"
    "Api.ServiceInterface"
)

# === Implementare ===
SCRIPT_NAME="$(basename "$0")"
FOUND_FLAGS=0
FLAGGED_FILES=()

echo ""
echo "🔍 SuperNicu G8 — Query Tenant Check (WARN-only)"
echo ""

for entity in "${INDIRECT_ENTITIES[@]}"; do
    for dir in "${QUERY_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        # Caută fișiere care folosesc entitatea într-un QueryOver / Query
        files=$(grep -rl "QueryOver<${entity}>\|Query<${entity}>\|<${entity}>(" "$dir" 2>/dev/null || true)

        for file in $files; do
            # Heuristic: verifică dacă fișierul conține "team_id" SAU "TeamId" în context de WHERE/JoinAlias
            # NU validează structura — doar prezența string-ului ca SEMNAL.
            if ! grep -qE "(team_id|TeamId)" "$file"; then
                FOUND_FLAGS=$((FOUND_FLAGS + 1))
                FLAGGED_FILES+=("$file")
                echo "  ⚠ $file"
                echo "    → Entitate indirect tenant-scoped: $entity"
                echo "    → Pattern suspect: lipsește 'team_id' / 'TeamId' în fișier."
                echo "    → Routare: review-bono trebuie să verifice JOIN explicit pe parent."
                echo ""
            fi
        done
    done
done

# === Raport ===
if [ $FOUND_FLAGS -eq 0 ]; then
    echo "✓ Nu s-au găsit queries suspecte pe entități indirect tenant-scoped."
    echo "  (Nota: absența flag-urilor NU garantează tenant scoping corect — review-bono decide.)"
    exit 0
fi

echo "═══════════════════════════════════════════════════════"
echo "📋 ${FOUND_FLAGS} fișier(e) flag-uit(e) pentru review structural"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Acțiune obligatorie:"
echo "  1. Rulează review-bono PE ACESTE FIȘIERE specific:"
echo ""
for f in "${FLAGGED_FILES[@]}"; do
    echo "     - $f"
done
echo ""
echo "  2. Brief pentru review-bono:"
echo "     'Verifică tenant scoping la query layer (G8). Defense-in-depth"
echo "     cere JOIN explicit pe parent + parent.team_id în WHERE. Service-layer"
echo "     check NU contează ca al doilea strat — e backup, nu primary.'"
echo ""
echo "Mode: WARN-only (commit-ul continuă). Hook-ul promovat la BLOCK"
echo "doar după validare empirică pe 2-3 proiecte (false positives ≈ 0)."
echo ""

# WARN-only: exit 0 indiferent de flags
exit 0
