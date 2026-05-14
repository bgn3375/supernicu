#!/bin/bash
# SuperNicu — Auto-build Query Safety Matrix from FluentNHibernate mappings + queries
#
# Output: docs/architect/query-safety-matrix.md
# Run: bash hooks/build-query-safety-matrix.sh [project-root]
#
# Portable: works with bash 3.2+ (macOS default) via tmp files, not associative arrays
#
# Detectează automat:
# - Direct tenant-scoped: entități cu Map(x => x.TeamId)
# - Indirect tenant-scoped: entități fără team_id direct, dar cu References() către o entitate tenant-scoped
# - Global by design: restul
# - Pentru Indirect: scanează *Query.cs pentru pattern JoinAlias + parent.TeamId

set +e

PROJECT_ROOT="${1:-$(pwd)}"
MAPPINGS_DIR="$PROJECT_ROOT/PnL.Infrastructure.NHibernate/Mappings"
QUERIES_DIR="$PROJECT_ROOT/PnL.DomainServices"
SCHEMA_FILE="$PROJECT_ROOT/schema.sql"
OUTPUT_DIR="${OUTPUT_DIR_OVERRIDE:-$PROJECT_ROOT/docs/architect}"
OUTPUT_FILE="$OUTPUT_DIR/query-safety-matrix.md"

# Fallback paths
if [ ! -d "$MAPPINGS_DIR" ]; then
    MAPPINGS_DIR=$(find "$PROJECT_ROOT" -maxdepth 4 -type d -name "Mappings" 2>/dev/null | head -1)
fi
if [ ! -d "$QUERIES_DIR" ]; then
    QUERIES_DIR=$(find "$PROJECT_ROOT" -maxdepth 4 -type d -name "DomainServices" 2>/dev/null | head -1)
fi

if [ ! -d "$MAPPINGS_DIR" ]; then
    echo "ERROR: Cannot find Mappings directory under $PROJECT_ROOT"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# State files (replace associative arrays for bash 3.2)
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

DIRECT_LIST="$WORK/direct.txt"      # entities with team_id direct
ENTITY_MAP="$WORK/entity-map.txt"   # entity -> map file (tab-separated)
ROWS_FILE="$WORK/rows.txt"          # markdown rows

: > "$DIRECT_LIST"
: > "$ENTITY_MAP"
: > "$ROWS_FILE"

# ─── Pass 1: identifică entitățile ───
for map_file in "$MAPPINGS_DIR"/*Map.cs; do
    [ -f "$map_file" ] || continue

    entity=$(grep -oE "ClassMap<[A-Z][A-Za-z0-9]+>" "$map_file" | head -1 | sed -E 's/ClassMap<(.+)>/\1/')
    [ -z "$entity" ] && continue

    map_basename=$(basename "$map_file")
    printf "%s\t%s\n" "$entity" "$map_basename" >> "$ENTITY_MAP"

    # Direct tenant-scoped?
    if grep -qE "Map\(x => x\.TeamId\)|Column\(['\"]team_id['\"]\)" "$map_file"; then
        echo "$entity" >> "$DIRECT_LIST"
    fi
done

# ─── Pass 2: clasifică fiecare entitate ───

ISSUE_COUNT=0
INDIRECT_COUNT=0
GLOBAL_UNDOC_COUNT=0
MISSING_FILTER_COUNT=0
BAD_QUERY_COUNT=0

while IFS=$'\t' read -r entity map_basename; do
    [ -z "$entity" ] && continue
    map_file="$MAPPINGS_DIR/$map_basename"

    # Direct tenant-scoped check
    if grep -qFx "$entity" "$DIRECT_LIST"; then
        if grep -qE "ApplyFilter<TenantFilterDefinition>|tenantFilter" "$map_file"; then
            classification="Direct tenant-scoped"
            issue=""
        else
            classification="Direct tenant-scoped"
            issue="(!) MISSING TenantFilter"
            MISSING_FILTER_COUNT=$((MISSING_FILTER_COUNT + 1))
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        fi
        printf "| \`%s\` | \`%s\` | Da | — | %s %s | — |\n" \
            "$entity" "$map_basename" "$classification" "$issue" >> "$ROWS_FILE"
        continue
    fi

    # Indirect tenant-scoped check: caută References() la o entitate Direct
    fk_to_scoped=""
    while IFS= read -r reference; do
        [ -z "$reference" ] && continue
        # Caută exact + variante (TeamX, BonoX, etc.)
        while IFS= read -r direct_entity; do
            [ -z "$direct_entity" ] && continue
            if [ "$direct_entity" = "$reference" ] || \
               [[ "$direct_entity" == *"$reference" ]] || \
               [[ "$reference" == *"$direct_entity" ]]; then
                fk_to_scoped="$direct_entity"
                break 2
            fi
        done < "$DIRECT_LIST"
    done < <(grep -oE "References\(x => x\.[A-Z][A-Za-z0-9]+\)" "$map_file" 2>/dev/null | \
             sed -E 's/References\(x => x\.(.+)\)/\1/')

    if [ -n "$fk_to_scoped" ]; then
        classification="Indirect tenant-scoped"
        INDIRECT_COUNT=$((INDIRECT_COUNT + 1))
        bad_queries=""

        if [ -d "$QUERIES_DIR" ]; then
            while IFS= read -r query_file; do
                [ -z "$query_file" ] && continue

                # Opt-out: query intenționat cross-tenant cu marker explicit
                # Convenție: comentariu `// CROSS-TENANT: <motiv>` (case-sensitive, format strict)
                if grep -qE "^[[:space:]]*//[[:space:]]*CROSS-TENANT:[[:space:]]+" "$query_file" 2>/dev/null; then
                    continue
                fi

                # Verifică pattern JoinAlias + parent.TeamId
                has_join=0
                has_parent_team=0
                grep -q "JoinAlias" "$query_file" 2>/dev/null && has_join=1
                grep -qE "\.TeamId\s*==" "$query_file" 2>/dev/null && has_parent_team=1
                if [ "$has_join" = "0" ] || [ "$has_parent_team" = "0" ]; then
                    bad_queries="${bad_queries}\`$(basename "$query_file")\` "
                    BAD_QUERY_COUNT=$((BAD_QUERY_COUNT + 1))
                fi
            done < <(grep -rlE "QueryOver<[[:space:]]*${entity}[[:space:]]*>|Query<[[:space:]]*${entity}[[:space:]]*>|Command<[[:space:]]*${entity}[[:space:]]*>" \
                     "$QUERIES_DIR" 2>/dev/null | grep -E '(Query|Command)\.cs$')
        fi

        if [ -z "$bad_queries" ]; then
            queries_issue="OK"
        else
            queries_issue="$bad_queries"
            ISSUE_COUNT=$((ISSUE_COUNT + 1))
        fi

        printf "| \`%s\` | \`%s\` | Nu | \`%s\` | %s | %s |\n" \
            "$entity" "$map_basename" "$fk_to_scoped" "$classification" "$queries_issue" >> "$ROWS_FILE"
        continue
    fi

    # Global by design
    if grep -qiE "(global|cross-tenant|pre-tenant|pre-auth|by design)" "$map_file"; then
        classification="Global by design (documented)"
    else
        classification="Global by design (! UNDOCUMENTED — add comment)"
        GLOBAL_UNDOC_COUNT=$((GLOBAL_UNDOC_COUNT + 1))
        ISSUE_COUNT=$((ISSUE_COUNT + 1))
    fi
    printf "| \`%s\` | \`%s\` | Nu | — | %s | — |\n" \
        "$entity" "$map_basename" "$classification" >> "$ROWS_FILE"

done < "$ENTITY_MAP"

# ─── Build output file ───
{
echo "# Query Safety Matrix"
echo ""
echo "**Generat automat:** $(date '+%Y-%m-%d %H:%M:%S')"
echo "**Sursă:** \`$MAPPINGS_DIR\` (FluentNH ClassMaps)"
echo ""
echo "Acest fișier e regenerat de \`hooks/build-query-safety-matrix.sh\`. Modificările manuale se pierd la următoarea rulare."
echo ""
echo "## Clasificare per entitate"
echo ""
echo "| Entitate | Mapping | team_id direct? | FK către tenant-scoped? | Clasificare | Queries fără JOIN+parent.TeamId |"
echo "|----------|---------|-----------------|--------------------------|-------------|-----------------------------------|"
cat "$ROWS_FILE"

echo ""
echo "## Pattern obligatoriu pentru Indirect tenant-scoped queries"
echo ""
echo '```csharp'
echo "public class LoadChildByIdQuery(Guid id, string teamId)"
echo "    : NHibernate{Project}Query<ChildEntity>"
echo "{"
echo "    protected override ChildEntity OnExecute()"
echo "    {"
echo "        ChildEntity child = null;"
echo "        ParentEntity parent = null;"
echo "        return Session.QueryOver(() => child)"
echo "            .JoinAlias(() => child.Parent, () => parent)"
echo "            .Where(() => child.Id == id && parent.TeamId == teamId)"
echo "            .SingleOrDefault();"
echo "    }"
echo "}"
echo '```'

echo ""
echo "## Global by design — comentariu obligatoriu în mapping"
echo ""
echo "Pentru fiecare entitate Global, mapping-ul TREBUIE să conțină comentariu explicit. Exemple acceptabile:"
echo ""
echo '```csharp'
echo "// global by design — currency rates partajate cross-tenant"
echo "// pre-tenant — request înainte de a avea cont"
echo "// pre-auth — keyed pe email, înainte de login"
echo '```'

echo ""
echo "## Summary"
echo ""
echo "- **Total entități:** $(wc -l < "$ENTITY_MAP" | xargs)"
echo "- **Direct tenant-scoped:** $(wc -l < "$DIRECT_LIST" | xargs)"
echo "- **Indirect tenant-scoped:** $INDIRECT_COUNT"
echo "- ⚠️  **Missing TenantFilter:** $MISSING_FILTER_COUNT"
echo "- ⚠️  **Undocumented Global:** $GLOBAL_UNDOC_COUNT"
echo "- ⚠️  **Indirect queries fără JOIN+parent.TeamId:** $BAD_QUERY_COUNT"
echo ""
if [ "$ISSUE_COUNT" -gt 0 ]; then
    echo "**Status:** ❌ $ISSUE_COUNT issue(s) detected. Review & fix before Phase 3."
else
    echo "**Status:** ✅ Clean."
fi
} > "$OUTPUT_FILE"

# ─── Console summary ───
echo "Query Safety Matrix generated: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  Total entities: $(wc -l < "$ENTITY_MAP" | xargs)"
echo "  Direct tenant-scoped: $(wc -l < "$DIRECT_LIST" | xargs)"
echo "  Indirect tenant-scoped: $INDIRECT_COUNT"
echo "  ⚠️  Missing TenantFilter: $MISSING_FILTER_COUNT"
echo "  ⚠️  Undocumented Global: $GLOBAL_UNDOC_COUNT"
echo "  ⚠️  Indirect queries without JOIN+parent.TeamId: $BAD_QUERY_COUNT"

if [ "$ISSUE_COUNT" -gt 0 ]; then
    echo ""
    echo "❌ $ISSUE_COUNT issue(s) detected. Review $OUTPUT_FILE and fix before proceeding to Phase 3."
    exit 1
fi

echo ""
echo "✅ Query Safety Matrix clean."
exit 0
