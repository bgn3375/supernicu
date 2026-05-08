# Eval: nicu-verify prinde secret în cod frontend

## Tip: verify-code (security)
## Ce testează: Zero secrets în frontend

## Input (cod cu bug intenționat)

```typescript
// app/actions/auth.ts
const API_KEY = 'sk-live-abc123def456';

export async function login(email: string) {
  const res = await fetch(`${API_URL}/api/auth/magic-link`, {
    headers: { 'X-Api-Key': API_KEY },
  });
}
```

## Expected: FAIL

```
- [FAIL] Secret hardcodat în app/actions/auth.ts: "sk-live-abc123def456"
- Contract punct: "Niciun secret în cod frontend?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
