---
name: forms
description: React form implementation skill for Next.js 15. Create, edit, validation, mutation, error handling. Fires on "form", "create form", "edit form", "validation", "submit".
---

# Forms — React Forms in Next.js 15

Pattern-uri pentru formulare: creare, editare, validare, submit.

## Stack

- Next.js 15 App Router
- React 19
- TanStack React Query 5 (useMutation)
- shadcn/ui form components (Input, Select, Dialog, etc.)
- Tailwind CSS + Bono The Edge tokens

## Pattern: Create/Edit Form

### 1. Mutation hook

```typescript
// hooks/useCreateExpense.ts
export function useCreateExpense(teamId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateExpenseRequest) =>
      createExpense(teamId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['expenses', teamId] });
    },
  });
}
```

### 2. Form component

```typescript
// components/expenses/ExpenseForm.tsx
'use client'

export function ExpenseForm({ teamId, expense, onClose }: Props) {
  const create = useCreateExpense(teamId);
  const update = useUpdateExpense(teamId);
  const isEdit = !!expense;

  const [form, setForm] = useState<FormData>(
    expense ?? { amount: 0, currency: 'RON', categoryId: '' }
  );

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const mutation = isEdit ? update : create;
    await mutation.mutateAsync(isEdit ? { id: expense.id, ...form } : form);
    onClose();
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* form fields */}
      <Button type="submit" disabled={create.isPending || update.isPending}>
        {isEdit ? 'Salvează' : 'Adaugă'}
      </Button>
    </form>
  );
}
```

### 3. Container (Dialog sau Page)

```typescript
// Inline dialog
<Dialog open={open} onOpenChange={setOpen}>
  <DialogContent>
    <ExpenseForm teamId={teamId} onClose={() => setOpen(false)} />
  </DialogContent>
</Dialog>
```

## Validare

- Client-side: validare pe submit (required fields, format, range)
- Server-side: OperationResult cu error codes din backend
- Afișare erori: per-field (sub input) + general (toast)

## Reguli

1. **useMutation** din TanStack Query, nu fetch direct.
2. **Invalidare cache** la onSuccess (queryClient.invalidateQueries).
3. **Loading state** pe butonul de submit (isPending).
4. **Error handling:** afișare eroare din OperationResult.
5. **Stiluri din prototip.** Componente shadcn/ui, tokens Bono The Edge.
6. **Limba română** pe labels și placeholder-uri.
7. **Dark mode** suportat.
8. **Max 150 linii** per fișier form.
