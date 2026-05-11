# react-19-vite-frontend — CHANGELOG

Version scheme: `MAJOR.MINOR.PATCH`. MAJOR for breaking placeholder/token/section-name changes that require consumer re-copying; MINOR for new rules/templates/patterns; PATCH for typo, citation drift, and minor copy fixes.

---

## 1.7.0 — 2026-04-23

**SKILL.md**

- Tightened `description:` from ~1000 chars to ~820 chars. Dropped redundant form enumeration (`login, settings, password-reset, create/edit/delete`) — "forms" alone covers them — and removed the `(Radix)` parenthetical already implied by shadcn/ui. Leaves ~200 chars of headroom under Anthropic's 1024-char cap.
- Replaced four brittle `file.ts:N-M` line-number citations with symbol-anchor form (`file.ts § anchor-name`). Targets: `useItemsInfiniteQuery.ts`, `ItemListItem.tsx`, `button.tsx`, `useInfiniteScroll.ts`. Rationale: consumer files drift, line numbers go stale silently; symbol anchors survive refactors.
- Deduplicated the "React 19 idioms" anti-pattern block — 7 bullets collapsed to a 7-row index pointing at the corresponding `§` sections of `references/react-19-hooks.md`. Single source of truth per rule; removes drift risk between SKILL.md and the reference.

**references/**

- Split `references/worked-example.md` (495 L → 90 L). The file is now a narrative + decision commentary; every code block has moved under `references/templates/*.tmpl`.
- Added `references/templates/` with 10 copy-paste artefacts:
  - `types.ts.tmpl`
  - `queryKeys.ts.tmpl`
  - `service.ts.tmpl`
  - `useInfiniteQuery.ts.tmpl`
  - `useDeleteMutation.ts.tmpl`
  - `filterOptions.ts.tmpl`
  - `ListHeader.tsx.tmpl`
  - `ListItem.tsx.tmpl`
  - `ListSkeleton.tsx.tmpl`
  - `EmptyState.tsx.tmpl`
  - `Page.tsx.tmpl`
  - `router-entries.tsx.tmpl`
- Added this CHANGELOG.

**Migration notes for consumers**

- No behavioural change — rules and decisions are the same, only the navigation topology changed.
- Line-number citations in existing consumer-project code comments that reference this skill's old precedent locations are still valid against the consumer's own files; the skill simply no longer prints those line numbers.
- If you loaded `references/worked-example.md` expecting a full file dump, load `references/templates/*.tmpl` instead for raw code; the narrative stays in `worked-example.md`.

---

## 1.6.0 — 2026-04-23

Review-fix pass. See commit `0a0819d`.

## 1.0.0 — pre-2026-04-23

Initial skill. See commit `698f0d4`.
