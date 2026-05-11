# Forms — Plain React 19 + Per-Field Errors

The template uses plain `useState` for every field plus a single `useState<FieldErrors>({})` object for per-field error messages. **No** `useActionState`, **no** `<form action={…}>` server-action syntax, **no** form library (react-hook-form, Formik, etc.) — migrating is a template-level decision. Rationale: `SKILL.md` § Anti-patterns and `references/react-19-hooks.md` § `useActionState`; additional detail in § Why not `useActionState` below.

Canonical examples: `src/pages/Login.tsx` (thin, no field errors) and `src/pages/Settings.tsx` (full — multi-field validation + error-code map + eye-toggle password inputs).

## Minimal form — `Login.tsx` shape

```tsx
const [email, setEmail] = useState('');
const [password, setPassword] = useState('');
const [isLoading, setIsLoading] = useState(false);

async function handleSignIn(e: React.FormEvent) {
  e.preventDefault();
  setIsLoading(true);

  const authenticationError = 'Authentication failed. Please check your credentials and try again.';

  try {
    const isAuthenticated = await authService.login(email, password);
    if (isAuthenticated) {
      toast.success('Login successful', { description: 'Welcome back!' });
      window.location.href = '/';
    } else {
      toast.error(authenticationError, { duration: TOAST_DURATION_MS });
    }
  } catch {
    toast.error(authenticationError, { duration: TOAST_DURATION_MS });
  } finally {
    setIsLoading(false);
  }
}
```

Notes:

- `isLoading` is owned by the page, not the service — even though `authService.login` is async. Mutations via TanStack Query replace this with `mutation.isPending`.
- `window.location.href = '/'` (not `navigate('/')`) forces a full reload after login so the protected-route loader re-runs against fresh cookies. Keep this for auth flows; for other post-submit redirects use `useNavigate`.
- Toast duration uses `TOAST_DURATION_MS` from `@/lib/constants` (5 s). Do not hardcode.

## Full form — `Settings.tsx` shape

Six moving parts:

1. Field state — one `useState` per field.
2. Error state — one `useState<FieldErrors>({})` with an interface declared at the top of the file.
3. Visibility state (for password inputs) — one `useState<boolean>` per field.
4. `clearForm()` — resets everything including visibility toggles.
5. `validate()` — returns `boolean`, calls `setFieldErrors(errors)`, early-returns in `handleSubmit`.
6. `handleSubmit` — `preventDefault` → guard on `isPending` → `validate()` → `mutation.mutate(payload, { onSuccess, onError })`.

```tsx
interface FieldErrors {
  currentPassword?: string;
  newPassword?: string;
  confirmPassword?: string;
}

const [currentPassword, setCurrentPassword] = useState('');
const [newPassword, setNewPassword] = useState('');
const [confirmPassword, setConfirmPassword] = useState('');
const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});

const changePasswordMutation = useChangePassword();

const validate = (): boolean => {
  const errors: FieldErrors = {};

  if (!currentPassword) errors.currentPassword = 'Current password is required';

  if (!newPassword) errors.newPassword = 'New password is required';
  else if (newPassword.length < 8) errors.newPassword = 'New password must be at least 8 characters';
  else if (newPassword === currentPassword) errors.newPassword = 'New password must be different from current password';

  if (newPassword !== confirmPassword) errors.confirmPassword = 'Passwords do not match';

  setFieldErrors(errors);
  return Object.keys(errors).length === 0;
};

const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault();
  if (changePasswordMutation.isPending) return;
  if (!validate()) return;

  changePasswordMutation.mutate(
    { currentPassword, newPassword },
    {
      onSuccess: (data) => {
        if (data.ok) {
          toast.success('Password changed successfully', { duration: TOAST_DURATION_MS });
          clearForm();
          return;
        }
        switch (data.errorCode) {
          case 'InvalidCurrentPassword':
            setFieldErrors({ currentPassword: 'Current password is incorrect' });
            break;
          case 'PasswordTooShort':
            setFieldErrors({ newPassword: 'New password must be at least 8 characters' });
            break;
          case 'UserNotFound':
            toast.error('User not found', { duration: TOAST_DURATION_MS });
            break;
          case 'ServiceUnavailable':
            toast.error('Service unavailable. Please try again.', { duration: TOAST_DURATION_MS });
            break;
          default:
            toast.error('Password change failed', { duration: TOAST_DURATION_MS });
        }
      },
      onError: (error) => {
        errorService.handleApiError(normalizeError(error), { operation: 'change-password' });
      },
    }
  );
};
```

Observations that are not obvious:

- **Known error codes go to field errors; unknown failures go to `onError` → `errorService`.** The distinction is: codes describe known business outcomes (validation, state); `onError` fires on network/5xx/auth. Do not collapse them.
- **`onSuccess` can still be a failure** (`data.ok === false`). `useMutation` only considers a thrown error a failure. This is why the success branch carries a switch.
- **`toast.error` for known codes** when no field is the natural target (e.g. `UserNotFound`). Prefer field errors otherwise — they surface next to the offending input.

## Why not `useActionState`

`useActionState` is designed around `<form action={submitAction}>` + `FormData`. Three concrete reasons the template does not adopt it:

1. **Per-field error-code branching.** Our forms own per-field React state so `onSuccess` can `switch (data.errorCode)` and set `fieldErrors.currentPassword` or `fieldErrors.newPassword` next to the offending input (`Settings.tsx:78-93`). A `FormData`-driven flow returns a single reduced state and loses the per-field mapping without re-implementing the same error map in the action.
2. **Clear-on-change UX.** The `onChange` → clear-this-field-only pattern depends on having per-field state. Moving the form to `FormData` pushes error clearing back onto a different mechanism (controlled submission state, manual resets) which adds ceremony without reducing code.
3. **Error-service coordination.** `errorService.handleApiError(err, { operation })` is wired to the mutation's `onError` branch and to the `Operation` union in `src/services/errorService.ts`. Adopting `useActionState` would require re-piping the operation-aware error dispatch through the action return path, touching every form and the service at once.

This is a template-level decision, not a personal preference. If you want the template to migrate, raise a template-level RFC with the frontend tech lead first. Do not apply `useActionState` feature-locally — mixed-pattern forms are worse than either pure alternative.

`useFormStatus` is separately adoptable without moving to Actions — it reads from the nearest ancestor `<form>` and does not require `<form action>`. See `references/react-19-hooks.md` § `useFormStatus` for when it earns its keep.

## Clear-on-change error handling

On every field's `onChange`, clear only that field's error:

```tsx
onChange={(e) => {
  setCurrentPassword(e.target.value);
  if (fieldErrors.currentPassword) {
    setFieldErrors((prev) => ({ ...prev, currentPassword: undefined }));
  }
}}
```

Guard the `setFieldErrors` call with `if (fieldErrors.currentPassword)` so renders do not churn on every keystroke when there is no error to clear.

## Error rendering

```tsx
{fieldErrors.currentPassword && (
  <p className="text-sm text-destructive">{fieldErrors.currentPassword}</p>
)}
```

Never render the full error object; render one `<p>` per field with the destructive colour token. Screen readers pick up the association via the adjacent `<Label htmlFor>`.

## Submit button

```tsx
<Button
  type="submit"
  className="w-full"
  isLoading={mutation.isPending}
  loadingText="Saving..."
>
  Change Password
</Button>
```

`Button` (`src/components/ui/button.tsx`) accepts `isLoading` and `loadingText` — it renders a `<Loader2 className="animate-spin" />` and swaps children automatically. Do **not** roll your own spinner inside the button.

## Password inputs — eye toggle

```tsx
const [showPassword, setShowPassword] = useState(false);

<div className="relative">
  <Input
    id="password"
    type={showPassword ? 'text' : 'password'}
    value={value}
    onChange={…}
    disabled={isPending}
    required
    autoComplete="current-password"  // or "new-password"
    className="pr-9"
  />
  <button
    type="button"
    onClick={() => setShowPassword((v) => !v)}
    className="text-muted-foreground hover:text-foreground absolute right-2.5 top-1/2 -translate-y-1/2"
    tabIndex={-1}
    aria-label={showPassword ? 'Hide password' : 'Show password'}
  >
    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
  </button>
</div>
```

Details that matter:

- `tabIndex={-1}` — the toggle is not in the tab order; users tab from the input straight to the next field.
- `type="button"` — prevents accidental submit on Enter.
- `autoComplete` — `current-password` for sign-in / current-field; `new-password` for new / confirm fields. Browser password managers depend on this.
- `className="pr-9"` on the `Input` — leaves room for the absolute-positioned button.

## Toast status classes

Sonner toasts gain a coloured left border + icon tint via CSS classes in `src/styles/main.css`:

- `toast-success` — `#15B79F` (teal, matches `--success` token)
- `toast-error` — `#ef4444`
- `toast-info` — `#3b82f6`
- `toast-warning` — `#f59e0b`

Apply via the sonner API:

```tsx
toast.success('Saved', { className: 'toast-success', duration: TOAST_DURATION_MS });
```

Default sonner usage (`toast.success('…')`) already styles correctly in most cases — only add the class when you need the coloured border specifically.

## Confirmation before destructive mutation

Use `<ConfirmDialog />` from `@/components/dialog/ConfirmDialog`:

```tsx
const [confirmOpen, setConfirmOpen] = useState(false);
const deleteMutation = useDelete{Feature}();

<ConfirmDialog
  open={confirmOpen}
  onOpenChange={setConfirmOpen}
  title="Delete {feature}?"
  description="This action cannot be undone."
  variant="destructive"
  confirmLabel="Delete"
  cancelLabel="Cancel"
  onConfirm={async () => {
    await deleteMutation.mutateAsync(id);
    queryClient.invalidateQueries({ queryKey: {feature}QueryKeys.all });
    toast.success('Deleted', { duration: TOAST_DURATION_MS });
  }}
/>
```

Contract (from `src/components/dialog/ConfirmDialog.tsx:38-63`):

- `onConfirm` may return `void` or `Promise<void>`. If it throws, the dialog stays open so the user can retry.
- While awaiting `onConfirm`, the dialog is locked — `onOpenChange` is ignored, both buttons are disabled, and the confirm button renders a spinner.
- Default labels are Romanian (`Confirmare` / `Anulare`). Override for English contexts via the `confirmLabel` / `cancelLabel` props.

## Do not

- Do not introduce react-hook-form, Formik, or similar. Plain `useState` is the convention.
- Do not use uncontrolled inputs (`defaultValue` + `ref`) — validation lives in `validate()` with full state visibility.
- Do not run `validate()` on every keystroke — only clear the touched field's error on change; re-validate on submit.
- Do not call `mutation.mutate` without the `{ onSuccess, onError }` object — handling needs to stay on the page to preserve error-code branching.
- Do not swallow mutation errors with an empty `onError`. Always hand to `errorService.handleApiError`.
- Do not `toast.error` inside `onError` for API failures — `errorService.handleApiError` already does. Direct `toast.error` is for UX feedback (validation, clipboard, etc.).
- Do not interpolate `data.errorCode`, `data.errorMessage`, or any server-returned string directly into `toast.error(...)` / `toast.success(...)`. Always map known codes to hardcoded user-safe copy strings (the `switch` in `Settings.tsx:78-93` is the pattern). Server strings may contain PII, internal path details, or entity names that are not intended for end-user display.
- Do not derive the post-submit redirect from a user-supplied value. Hardcode the destination (`window.location.href = '/'` for auth flows; `useNavigate()('/items')` for in-app moves). If redirect-back is required (e.g. deep-link login), gate `searchParams.get('redirectTo')` through `isSafeRedirect` from `@/lib/redirect` (see `references/router-and-layouts.md` § `isSafeRedirect`) and fall back to `'/'`. Do not hand-roll `value.startsWith('/')` — it passes `//evil.com`.
