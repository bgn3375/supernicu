# Test Patterns — BONO

## Backend Testing (xUnit + SQLite)

### Test Location
`[Project].Api.Tests/`

### Run Commands
```bash
# All tests
dotnet test [Project].Api.Tests/ --verbosity normal

# With Docker (no local SDK needed)
docker run --rm -v "$(pwd):/src" -w /src mcr.microsoft.com/dotnet/sdk:10.0 \
  dotnet test [Project].Api.Tests/ --verbosity normal

# Specific test
dotnet test --filter "FullyQualifiedName~MyEntityQueryTests"
```

## Frontend Testing (Vitest + Playwright)

### Run Commands
```bash
# Unit tests
npm test

# E2E tests
npx playwright test

# With UI
npx playwright test --ui

# Specific test
npx playwright test my-feature.spec.ts
```

## Manual UI Verification

### Dev Server
```bash
npm run dev
# Opens on localhost:3000
```

### Checklist per page
For each page, verify:
1. Page loads without errors (check browser console)
2. Layout matches prototype / SPEC
3. DS tokens applied correctly (bej-0/1, ink, fog, pink, no gradients)
4. Interactive elements work (buttons, dropdowns, toggles)
5. Data loads from API (or shows empty state)
6. Forms validate input
7. Navigation works (sidebar, back buttons, links)
