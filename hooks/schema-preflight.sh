#!/bin/bash
# SuperNicu — Schema Preflight Check
#
# Validează safety înainte de a aplica schema changes:
# - Schema Sync: schema.sql canonical vs local DB diff
# - Data preflight per migration: SQL safety queries care produc dovezi că migrația e safe
# - Cascade scan: detectează NHibernate Cascade.* și ON DELETE CASCADE care vor pierde semantica la soft-delete
#
# Run: bash hooks/schema-preflight.sh [project-root] [migration-sql-file]
# - dacă migration-sql-file e dat → analizează migration-ul specific
# - dacă nu → scan general (cascade chains + drift detection)
#
# Output: docs/architect/schema-preflight-[migration].md

set +e

PROJECT_ROOT="${1:-$(pwd)}"
MIGRATION_FILE="${2:-}"
MAPPINGS_DIR="$PROJECT_ROOT/PnL.Infrastructure.NHibernate/Mappings"
SCHEMA_FILE="$PROJECT_ROOT/schema.sql"
OUTPUT_DIR="${OUTPUT_DIR_OVERRIDE:-$PROJECT_ROOT/docs/architect}"

# Fallback paths
if [ ! -d "$MAPPINGS_DIR" ]; then
    MAPPINGS_DIR=$(find "$PROJECT_ROOT" -maxdepth 4 -type d -name "Mappings" 2>/dev/null | head -1)
fi
if [ ! -f "$SCHEMA_FILE" ]; then
    SCHEMA_FILE=$(find "$PROJECT_ROOT" -maxdepth 3 -name "schema.sql" 2>/dev/null | head -1)
fi

mkdir -p "$OUTPUT_DIR"

if [ -n "$MIGRATION_FILE" ]; then
    MIGRATION_NAME=$(basename "$MIGRATION_FILE" .sql)
    OUTPUT_FILE="$OUTPUT_DIR/schema-preflight-$MIGRATION_NAME.md"
else
    OUTPUT_FILE="$OUTPUT_DIR/schema-preflight-general.md"
fi

ISSUE_COUNT=0
WARN_COUNT=0

# ─── Helpers ───

emit() {
    echo "$@" >> "$OUTPUT_FILE"
}

# ─── Header ───

: > "$OUTPUT_FILE"
emit "# Schema Preflight Report"
emit ""
emit "**Generat:** $(date '+%Y-%m-%d %H:%M:%S')"
emit "**Project root:** \`$PROJECT_ROOT\`"
emit "**Schema canonical:** \`$SCHEMA_FILE\`"
if [ -n "$MIGRATION_FILE" ]; then
    emit "**Migration analizat:** \`$MIGRATION_FILE\`"
fi
emit ""

# ─── 1. CASCADE SCAN ───

emit "## 1. Cascade Behavior Inventory"
emit ""
emit "Detectează relații cu cascade care își pierd semantica la conversia hard-delete → soft-delete."
emit ""

# NHibernate cascades
emit "### 1.1 NHibernate Cascade.* (în mappings)"
emit ""
if [ -d "$MAPPINGS_DIR" ]; then
    NH_CASCADES=$(grep -rEn "Cascade\.(Delete|AllDeleteOrphan|All|SaveUpdate)" "$MAPPINGS_DIR" 2>/dev/null)
    if [ -n "$NH_CASCADES" ]; then
        emit "Relații cu NHibernate cascade detectate:"
        emit ""
        emit '```'
        echo "$NH_CASCADES" | sed "s|$MAPPINGS_DIR/||g" >> "$OUTPUT_FILE"
        emit '```'
        emit ""
        emit "⚠️  La conversia hard→soft delete pentru părinte, aceste cascade NU mai triggerează."
        emit "Documentează per relație: business cascade explicit (loop service) vs păstrează hard (rar)."
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        emit "Niciun NHibernate Cascade detectat."
    fi
else
    emit "❌ Mappings dir not found at $MAPPINGS_DIR"
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
fi

emit ""

# DB-level cascades
emit "### 1.2 DB-level ON DELETE CASCADE (în schema.sql)"
emit ""
if [ -f "$SCHEMA_FILE" ]; then
    DB_CASCADES=$(grep -nE "ON DELETE (CASCADE|SET NULL)" "$SCHEMA_FILE" 2>/dev/null)
    if [ -n "$DB_CASCADES" ]; then
        emit "Cascade FK constraints detectate:"
        emit ""
        emit '```sql'
        echo "$DB_CASCADES" >> "$OUTPUT_FILE"
        emit '```'
        emit ""
        emit "⚠️  La soft-delete pe părinte, aceste FK constraints NU se activează."
        emit "Pentru fiecare lanț: documentează ce trebuie făcut explicit în service (loop soft-delete copii)."
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        emit "Niciun DB cascade detectat."
    fi
else
    emit "❌ schema.sql not found at $SCHEMA_FILE"
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
fi
emit ""

# ─── 2. UNIQUE CONSTRAINTS + SOFT DELETE ───

emit "## 2. UNIQUE Constraints + Soft Delete Compatibility"
emit ""
emit "Tabelele cu UNIQUE indexes + soft delete intră în conflict când rândul soft-deleted blochează re-creare cu același key. Necesită \`deleted_marker\` generated column."
emit ""

if [ -f "$SCHEMA_FILE" ]; then
    emit "### Tabelele cu UNIQUE compound indexes"
    emit ""
    emit "| Tabel | UNIQUE Index | Are deleted_at? | Risc soft-delete |"
    emit "|-------|--------------|------------------|------------------|"

    # Extract toate tabelele + UNIQUE indexes
    awk '
        /^CREATE TABLE/ {
            # Extract table name: regex match anything that looks like an identifier
            # Pattern: "CREATE TABLE [IF NOT EXISTS] <name> ("
            tbl=$0
            sub(/^CREATE TABLE[[:space:]]+/, "", tbl)
            sub(/^IF NOT EXISTS[[:space:]]+/, "", tbl)
            sub(/[[:space:]]*\(.*$/, "", tbl)
            gsub(/[`]/, "", tbl)
            has_del=0
            n_uqs=0
            delete uq_arr
        }
        /deleted_at/ { has_del=1 }
        /UNIQUE (KEY|INDEX)/ {
            line=$0
            sub(/^[[:space:]]+/, "", line)
            sub(/,$/, "", line)
            n_uqs++
            uq_arr[n_uqs]=line
        }
        /^\) ENGINE/ {
            for (i=1; i<=n_uqs; i++) {
                uq=uq_arr[i]
                # Check if compound (more than 1 column inside parens)
                if (match(uq, /\([^)]*\)/) > 0) {
                    inner=substr(uq, RSTART+1, RLENGTH-2)
                    n_commas=gsub(/,/, ",", inner)
                    if (n_commas > 0) {
                        risk = (has_del == 1 ? "⚠️ Soft-delete blocked without deleted_marker" : "Hard-delete only — OK as-is")
                        has_del_str = (has_del == 1 ? "Da" : "Nu")
                        print "| `" tbl "` | `" uq "` | " has_del_str " | " risk " |"
                    }
                }
            }
        }
    ' "$SCHEMA_FILE" >> "$OUTPUT_FILE"

    emit ""
    emit "### Pattern \`deleted_marker\` pentru UNIQUE compound + soft-delete"
    emit ""
    cat >> "$OUTPUT_FILE" << 'SQL_PATTERN'
```sql
ALTER TABLE <tabel>
  ADD COLUMN deleted_marker CHAR(36)
    GENERATED ALWAYS AS (IFNULL(deleted_at, '0000-00-00')) VIRTUAL;
DROP INDEX <existing_uk> ON <tabel>;
CREATE UNIQUE INDEX <new_uk>
  ON <tabel> (<existing_cols>, deleted_marker);
```
SQL_PATTERN
fi
emit ""

# ─── 3. PREFLIGHT SQL QUERIES ───

if [ -n "$MIGRATION_FILE" ] && [ -f "$MIGRATION_FILE" ]; then
    emit "## 3. Preflight SQL Queries pentru migration"
    emit ""
    emit "Rulează aceste queries pe DB-ul **canonical** (production/staging) înainte de a aplica migration-ul:"
    emit ""

    # Parse migration pentru patterns specifice
    # ALTER COLUMN type
    ALTER_COLS=$(grep -iE "ALTER (TABLE|COLUMN).*MODIFY|CHANGE" "$MIGRATION_FILE" 2>/dev/null)
    if [ -n "$ALTER_COLS" ]; then
        emit "### 3.1 ALTER COLUMN type changes detectate"
        emit ""
        emit "Pentru fiecare ALTER MODIFY, verifică toate valorile existente încap în noul tip:"
        emit ""
        emit '```sql'
        emit "-- Pentru ALTER MODIFY team_id CHAR(36):"
        emit "SELECT DISTINCT LENGTH(team_id), COUNT(*) AS n FROM <tabel> GROUP BY 1 ORDER BY 1;"
        emit "-- Așteptat: doar lungime 36 (UUID). Orice altceva = data non-UUID, migrare blocked."
        emit '```'
        emit ""
    fi

    # ADD UNIQUE
    ADD_UNIQUES=$(grep -iE "ADD (UNIQUE|CONSTRAINT.*UNIQUE)|CREATE UNIQUE INDEX" "$MIGRATION_FILE" 2>/dev/null)
    if [ -n "$ADD_UNIQUES" ]; then
        emit "### 3.2 ADD UNIQUE constraint detectate"
        emit ""
        emit "Pentru fiecare UNIQUE nou, verifică că nu există duplicate:"
        emit ""
        emit '```sql'
        emit "SELECT <cols>, COUNT(*) AS dup FROM <tabel> GROUP BY <cols> HAVING dup > 1;"
        emit "-- Așteptat: zero rezultate. Orice rezultat = migration blocked."
        emit '```'
        emit ""
    fi

    # ADD soft-delete column
    ADD_SOFT=$(grep -iE "ADD COLUMN.*deleted_at|ADD.*deleted_at" "$MIGRATION_FILE" 2>/dev/null)
    if [ -n "$ADD_SOFT" ]; then
        emit "### 3.3 ADD soft-delete column detectat"
        emit ""
        emit "Pentru tabelele care primesc \`deleted_at\`:"
        emit "- Caută toate \`Session.Delete\` pe entitate"
        emit "- Caută \`Cascade.AllDeleteOrphan\` în mapping"
        emit "- Toate trebuie refactorizate la soft-delete + business cascade explicit"
        emit ""
        emit '```bash'
        emit "# Audit caller-uri DELETE pentru entitate <Entity>"
        emit "grep -rE 'Session\\.Delete.*$entity|Delete${entity}Command|new Cancel${entity}' PnL.DomainServices/"
        emit '```'
        emit ""
    fi
fi

# ─── 4. SUMMARY ───

emit "## Summary"
emit ""
emit "- **Issues blocante:** $ISSUE_COUNT"
emit "- **Warnings:** $WARN_COUNT"
emit ""
if [ "$ISSUE_COUNT" -gt 0 ]; then
    emit "**Status:** ❌ Migration blocked. Fix issues înainte de aplicare."
else
    if [ "$WARN_COUNT" -gt 0 ]; then
        emit "**Status:** ⚠️  Review warnings (cascade chains). Documentează decizii înainte de aplicare."
    else
        emit "**Status:** ✅ Preflight clean. Safe to apply."
    fi
fi

# ─── Console output ───

echo "Schema Preflight Report: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  Issues: $ISSUE_COUNT"
echo "  Warnings: $WARN_COUNT"
echo ""

if [ "$ISSUE_COUNT" -gt 0 ]; then
    echo "❌ Issues detected. Review $OUTPUT_FILE before applying migration."
    exit 1
fi

if [ "$WARN_COUNT" -gt 0 ]; then
    echo "⚠️  Warnings present. Review $OUTPUT_FILE — cascade decisions needed."
    exit 0  # warnings nu blochează
fi

echo "✅ Preflight clean."
exit 0
