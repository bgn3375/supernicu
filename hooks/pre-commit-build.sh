#!/bin/bash
# SuperNicu pre-commit hook: verifică build verde înainte de commit
# Instalare: cp hooks/pre-commit-build.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# Sau: ln -sf ../../hooks/pre-commit-build.sh .git/hooks/pre-commit

set -e

echo "🔨 SuperNicu: Verificare build..."

# Detectează tipul de proiect
if [ -f "*.sln" ] || ls *.sln 1>/dev/null 2>&1; then
    echo "  → .NET build..."
    dotnet build *.sln --no-restore --verbosity quiet
    if [ $? -ne 0 ]; then
        echo "❌ Backend build FAILED. Repară erorile înainte de commit."
        exit 1
    fi
    echo "  ✓ Backend build OK"
fi

if [ -f "package.json" ]; then
    echo "  → Frontend build..."
    npx tsc --noEmit 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ TypeScript errors. Repară înainte de commit."
        exit 1
    fi
    echo "  ✓ Frontend TypeScript OK"
fi

echo "✅ Build verification passed."
