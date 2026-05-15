#!/bin/bash
# SuperNicu — Secrets & Auth Endpoint Scan (G10, G11, G12)
#
# Detectează:
# - G10: secrets cu fallback hardcoded (`?? "..."` pe nume *Key*/*Secret*/*Password*/*Token*)
# - G11: auth tokens în URL query (backend [FromQuery] string token, frontend ?token=)
# - G12: endpoints [AllowAnonymous] fără [EnableRateLimiting]
#
# IMPORTANT: Hook-ul flag-ează tipare suspecte, NU validează structura.
# Output → review-bono care decide pass/fail.
#
# Mode: WARN-only (nu blochează commit-ul în primele 2-3 proiecte).
# Promovare la BLOCK: doar după validare empirică.
#
# Run: bash hooks/secrets-scan.sh [project-root]

set +e

PROJECT_ROOT="${1:-$(pwd)}"

# Detect project prefix (același pattern ca celelalte hook-uri)
detect_project_prefix() {
    local sln=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" -type f 2>/dev/null | head -1)
    if [ -n "$sln" ]; then
        basename "$sln" .sln | sed 's/.*\.//'
        return
    fi
    local infra_dir=$(find "$PROJECT_ROOT" -maxdepth 3 -type d -name "*.Infrastructure.NHibernate" 2>/dev/null | head -1)
    if [ -n "$infra_dir" ]; then
        basename "$infra_dir" | sed 's/\.Infrastructure\.NHibernate$//' | sed 's/.*\.//'
        return
    fi
    echo ""
}

PROJECT_PREFIX="${PROJECT_PREFIX:-$(detect_project_prefix)}"

if [ -n "$PROJECT_PREFIX" ]; then
    API_DIR="$PROJECT_ROOT/${PROJECT_PREFIX}.Api"
    SERVICE_DIR="$PROJECT_ROOT/${PROJECT_PREFIX}.DomainServices"
else
    API_DIR=$(find "$PROJECT_ROOT" -maxdepth 3 -type d -name "*.Api" 2>/dev/null | head -1)
    SERVICE_DIR=$(find "$PROJECT_ROOT" -maxdepth 3 -type d -name "*.DomainServices" 2>/dev/null | head -1)
fi

# Frontend directory (Next.js convention)
FRONTEND_DIRS=()
for d in "lib" "app" "components"; do
    if [ -d "$PROJECT_ROOT/$d" ]; then
        FRONTEND_DIRS+=("$PROJECT_ROOT/$d")
    fi
done

FLAGS_G10=0
FLAGS_G11=0
FLAGS_G12=0
FLAGGED_FILES=()

echo ""
echo "🔍 SuperNicu — Secrets & Auth Endpoint Scan (WARN-only)"
echo ""

# ─── G10: secrets cu fallback hardcoded ───
echo "━━━ G10: Secrets cu fallback ?? \"...\" ━━━"

if [ -d "$API_DIR" ]; then
    # Caută pattern: identificator cu Key/Secret/Password/Token/Pass + ?? "..."
    # Excludem comentariile (rândurile care încep cu //)
    matches=$(grep -rEn '(Key|Secret|Password|Token|Pass)[A-Za-z]*\s*\?\?\s*"[^"]+"' \
        "$API_DIR" --include="*.cs" 2>/dev/null | grep -v '^\s*//' || true)

    if [ -n "$matches" ]; then
        echo "$matches" | while IFS= read -r line; do
            echo "  ⚠ $line"
        done
        FLAGS_G10=$(echo "$matches" | wc -l | tr -d ' ')
        FLAGGED_FILES+=("G10 violations — see above")
    else
        echo "  ✓ Nu s-au găsit fallback-uri hardcoded pe nume sensibile."
    fi
fi
echo ""

# ─── G11: auth tokens în URL query ───
echo "━━━ G11: Auth tokens în URL query ━━━"

# Backend: [FromQuery] string (token|otp|code|magic|verify|reset)
if [ -d "$API_DIR" ]; then
    backend_matches=$(grep -rEn '\[FromQuery\]\s+string\s+(token|otp|code|magic|verify|reset)' \
        "$API_DIR" --include="*.cs" 2>/dev/null || true)

    if [ -n "$backend_matches" ]; then
        echo "  Backend (FromQuery cu nume sensibil):"
        echo "$backend_matches" | while IFS= read -r line; do
            echo "    ⚠ $line"
        done
        FLAGS_G11=$((FLAGS_G11 + $(echo "$backend_matches" | wc -l | tr -d ' ')))
    fi
fi

# Frontend: ?token=, ?otp=, ?code= în calls API
for fdir in "${FRONTEND_DIRS[@]}"; do
    frontend_matches=$(grep -rEn '\?(token|otp|code|magic|verify|reset)=' \
        "$fdir" --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v 'searchParams\|URLSearchParams' || true)

    if [ -n "$frontend_matches" ]; then
        echo "  Frontend (?token= în URL):"
        echo "$frontend_matches" | while IFS= read -r line; do
            echo "    ⚠ $line"
        done
        FLAGS_G11=$((FLAGS_G11 + $(echo "$frontend_matches" | wc -l | tr -d ' ')))
    fi
done

if [ $FLAGS_G11 -eq 0 ]; then
    echo "  ✓ Nu s-au găsit tokens în URL query string."
fi
echo ""

# ─── G12: AllowAnonymous fără EnableRateLimiting ───
echo "━━━ G12: Public-auth fără rate limiting ━━━"

if [ -d "$API_DIR" ]; then
    # Pentru fiecare [AllowAnonymous] în fișier, verifică prezența [EnableRateLimiting]
    # în BLOC-ul de atribute al aceleiași metode (oprește la prima declarație public/private/protected/internal)
    files_with_anon=$(grep -rl '\[AllowAnonymous\]' "$API_DIR" --include="*.cs" 2>/dev/null || true)

    G12_OUTPUT=$(for f in $files_with_anon; do
        awk -v fname="$f" '
            /\[AllowAnonymous\]/ {
                anon_line = NR
                anon_text = $0
                has_rate_limit = 0
                # scanează liniile următoare PÂNĂ la declarația metodei sau EOF
                while ((getline next_line) > 0) {
                    if (next_line ~ /\[EnableRateLimiting/) {
                        has_rate_limit = 1
                        break
                    }
                    # oprește la declarația metodei — atributele se aplică DOAR metodei imediat următoare
                    if (next_line ~ /^[[:space:]]*(public|private|protected|internal)[[:space:]]+/) {
                        break
                    }
                }
                if (!has_rate_limit) {
                    printf "%s:%d: %s\n", fname, anon_line, anon_text
                }
            }
        ' "$f" 2>/dev/null
    done)

    if [ -n "$G12_OUTPUT" ]; then
        echo "$G12_OUTPUT" | while IFS= read -r line; do
            echo "  ⚠ $line"
        done
        FLAGS_G12=$(echo "$G12_OUTPUT" | wc -l | tr -d ' ')
    else
        echo "  ✓ Toate [AllowAnonymous] au [EnableRateLimiting] în blocul de atribute."
    fi
fi
echo ""

# ─── Raport ───
TOTAL=$((FLAGS_G10 + FLAGS_G11 + FLAGS_G12))

echo "═══════════════════════════════════════════════════════"
echo "📋 Sumar"
echo "═══════════════════════════════════════════════════════"
echo "  G10 (secrets fallback):    $FLAGS_G10 flag(s)"
echo "  G11 (tokens în URL):       $FLAGS_G11 flag(s)"
echo "  G12 (rate limit lipsă):    $FLAGS_G12 flag(s)"
echo ""
echo "  TOTAL: $TOTAL flag(s)"
echo ""

if [ "$TOTAL" -eq 0 ]; then
    echo "✓ Scan curat. (Nota: absența flag-urilor NU garantează securitate — review-bono decide.)"
    exit 0
fi

echo "Acțiune obligatorie:"
echo "  1. Pentru fiecare flag de mai sus, rulează review-bono cu brief specific:"
echo ""
echo "     - G10 flags → 'Verifică că fallback-ul nu e secret real. Dacă da, replace cu throw at startup.'"
echo "     - G11 flags → 'Verifică că token-ul nu e auth secret. Dacă da, mută la POST body sau header.'"
echo "     - G12 flags → 'Verifică că endpoint-ul nu validează un secret. Dacă da, adaugă [EnableRateLimiting] + unified error + audit log.'"
echo ""
echo "  2. False positives sunt normale — review-bono filtrează."
echo "  3. Real positives — fix + re-rulează scan-ul."
echo ""
echo "Mode: WARN-only. Commit-ul continuă. Promovare la BLOCK după 2-3 proiecte cu false positives ≈ 0."
echo ""

# WARN-only: exit 0 indiferent de flags
exit 0
