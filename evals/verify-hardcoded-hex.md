# Eval: nicu-verify prinde hex hardcodat în frontend

## Tip: verify-code
## Ce testează: Design System — tokens only, nu hex hardcodat

## Input (cod cu bug intenționat)

```tsx
export function ExpenseCard({ expense }: Props) {
  return (
    <div className="bg-[#1a8a7d] text-white p-4 rounded-xl">
      <span style={{ color: '#EE4379' }}>{expense.amount}</span>
    </div>
  );
}
```

## Expected: FAIL

```
- [FAIL] Hex hardcodat #1a8a7d în ExpenseCard.tsx
- [FAIL] Hex hardcodat #EE4379 inline style în ExpenseCard.tsx
- Contract punct: "Culori din Bono The Edge, nu hex hardcodat?"
```

## Dacă nicu-verify raportează PASS → eval FAILED
