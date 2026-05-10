# Security Checklist — BONO

## Per-Feature Security Review

### 1. Multi-tenant Isolation (when product is multi-tenant)

For every new feature in a multi-tenant product, verify:
- [ ] New DB table has `team_id VARCHAR(255) NOT NULL`
- [ ] FluentNHibernate mapping has `ApplyFilter("tenantFilter", ...)`
- [ ] Query/Command classes receive `teamId` parameter
- [ ] Controller extracts `X-Team-Id` from headers
- [ ] No SQL queries without team_id filter
- [ ] No cross-tenant data exposure in response DTOs

### 2. Authentication & Authorization

- [ ] `[Authorize]` attribute on all non-public controllers
- [ ] Role-based access where needed (admin-only operations)
- [ ] JWT token validation middleware active
- [ ] Refresh token rotation (old token revoked on use)
- [ ] Magic link tokens expire (configurable, typically 15 min)

### 3. Input Validation

- [ ] Data Annotations on all request DTOs
- [ ] Null checks before processing
- [ ] String length limits (prevent oversized payloads)
- [ ] Enum validation (status values, roles)
- [ ] Date range validation
- [ ] Amount validation (positive, reasonable range)
- [ ] Currency validation (RON, EUR, USD, GBP only)

### 4. SQL Injection

- [ ] All queries use NHibernate parameterized (QueryOver, HQL with params)
- [ ] No string concatenation in SQL
- [ ] No `session.CreateSQLQuery()` with user input
- [ ] No raw SQL in command classes

### 5. XSS Prevention

- [ ] React escapes by default (no `dangerouslySetInnerHTML`)
- [ ] User input sanitized before display
- [ ] File names sanitized before storage
- [ ] No user input in `href` or `src` attributes without validation

### 6. File Upload Security

- [ ] Content-type validation (only allowed MIME types)
- [ ] Max file size enforced (server-side)
- [ ] File path sanitization (no path traversal: ../)
- [ ] Files stored in S3, not filesystem
- [ ] Pre-signed URLs with expiration for downloads

### 7. API Security

- [ ] CORS restrictive (only frontend domain)
- [ ] Rate limiting on auth endpoints
- [ ] Request size limits
- [ ] No sensitive data in URL params (use POST body or headers)
- [ ] Error responses don't leak internal details

### 8. Secrets Management

- [ ] No hardcoded credentials in source code
- [ ] JWT secret in environment variable
- [ ] S3 credentials in environment variable
- [ ] Database connection string in environment variable
- [ ] API keys (Mandrill, Conspectare) in environment variable
- [ ] No secrets in git history
