---
name: auth
description: Authentication and authorization skill. Magic Link + Google OAuth + JWT. 5 roles (Admin, Approver, Member, Accounting Viewer, Super-Admin). No passwords. Fires on "login", "authentication", "JWT", "roles", "permissions", "protected route".
---

# Auth — Magic Link + Google + JWT

Autentificare fără parolă. Două metode de login, 5 roluri.

## Metode de login

### 1. Magic Link
```
User introduce email → Backend generează token unic → Mandrill trimite email
→ User click pe link → Backend validează token → Returnează JWT
```
- Token valid 15 minute, single-use
- Email trimis prin Mandrill

### 2. Google OAuth
```
User click "Login with Google" → Redirect OAuth → Google returnează id_token
→ Backend validează id_token → Returnează JWT
```

### NU există
- Parolă clasică
- Register cu username/password
- Password reset
- BCrypt sau orice hashing de parole

## JWT

- **Access token:** valid 60 minute
- **Refresh token:** valid 7 zile
- **Claims:** userId, email, teamId, role
- **Reîmprospătare automată:** frontend-ul detectează 401, trimite refresh token, primește access token nou

## Cele 5 roluri

| Rol | Ce poate face |
|-----|---------------|
| **Admin** | Tot: setări firmă, categorii, bugete, aprobări, echipă, invitații |
| **Approver** | Vede toate cheltuielile, aprobă/respinge, nu poate schimba setări |
| **Member** | Adaugă cheltuieli proprii, le trimite la aprobare |
| **Accounting Viewer** | Vede toate cheltuielile, rapoarte. Nu poate modifica nimic |
| **Super-Admin** | Administrare platformă (toate firmele). Doar echipa BONO |

## Autorizare pe endpoint

Fiecare controller action are `[Authorize(Roles = "...")]`:

```csharp
[Authorize(Roles = "Admin,Approver")]
[HttpPost("approve")]
public async Task<IActionResult> ApproveExpense(...)
```

Matrice rol × acțiune se definește în architecture.md per modul.

## Frontend auth flow

```typescript
// Next.js server action
'use server'

export async function getExpenses(teamId: string) {
  const token = await getAccessToken(); // din cookies/session
  const response = await fetch(`${API_URL}/api/expenses`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'X-Team-Id': teamId,
    },
  });
  return response.json();
}
```

## Reguli

1. **No passwords.** Magic Link sau Google. Nimic altceva.
2. **JWT obligatoriu** pe toate endpoint-urile (except health check).
3. **Roluri din PRD.** 5 roluri exacte, nu improvizate.
4. **Refresh automat.** Frontend-ul nu cere re-login la expirare access token.
5. **X-Team-Id** pe fiecare request autentificat (vezi skill `multitenant`).

## Checklist

- [ ] Login Magic Link funcțional?
- [ ] Login Google OAuth funcțional?
- [ ] JWT access token 60 min?
- [ ] Refresh token 7 zile?
- [ ] Toate endpoint-urile au [Authorize]?
- [ ] Rolurile match PRD-ul (5 roluri)?
- [ ] Nicio referință la parolă/BCrypt?
- [ ] Frontend trimite X-Team-Id pe fiecare request?
