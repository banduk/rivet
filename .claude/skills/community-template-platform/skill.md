---
name: community-template-platform
description: Community template sharing platform — frontend UI, backend API routes, auth, KV storage
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/components/community/**`
- `packages/app/src/hooks/useUploadNewTemplate*.ts`
- `packages/app/src/hooks/useNewProjectFromTemplate.ts`
- `packages/app/src/utils/communityApi.ts`
- `packages/community/src/**`

Keywords: CommunityOverlay, RivetTemplateId, useUploadNewTemplate, community-profile, my-templates

---

You are working on the **community template sharing platform** for Rivet.

## Key Files
- `packages/app/src/components/community/CommunityOverlay.tsx` — nav shell; uses `ts-pattern` `match()` on `selectedNav` state to render pages
- `packages/app/src/components/community/CommunityTemplatesPage.tsx` — **empty placeholder**, not yet implemented
- `packages/app/src/components/community/EditTemplatePage.tsx` — template management; save/unpublish in `EditTemplateVersionPage` are **not yet wired**
- `packages/app/src/hooks/useUploadNewTemplate.ts` — two-step: POST to create, then PUT version with serialized project
- `packages/app/src/hooks/useNewProjectFromTemplate.ts` — deserializes, remaps all graph IDs, assigns new `ProjectId` via `nanoid()`
- `packages/app/src/utils/getCommunityApi.ts` — all fetches use `credentials: 'include'`; validates responses with `@recoiljs/refine` checkers
- `packages/community/src/lib/templates.ts` — KV storage; `templateParameters` and `canBeNode` are stubbed (always `{}` / `false`)
- `packages/community/src/app/api/templates/[templateId]/route.ts` — ownership checked as `template.author !== session.user.id`

## Key Concepts
- **Auth:** GitHub OAuth via NextAuth + custom KV adapter; session in cookies; all protected fetches need `credentials: 'include'`
- **KV keys:** `graph:{id}`, `graph:{id}:stars`, `user:{id}`, `user:email:{email}`, `user:github:{githubId}`
- **Version ordering:** stored array sorted by `semver.compare()`; UI displays DESC by `createdAt`; never use string sort
- **React Query cache keys:** `['community-profile']` (login state), `['my-templates']` (user's templates) — invalidate after mutations
- **Metadata extraction:** server calls `deserializeProject()` on upload to extract node count, inputs/outputs, graph names — client sends `plugins` array separately
- **Graph selection:** when uploading version of existing template, graphs pre-matched by name; renamed local graphs won't auto-match

## Critical Rules
- All fetch calls to community API must include `credentials: 'include'` or protected endpoints return 401
- When instantiating templates via `useNewProjectFromTemplate`, remap all graph IDs — missing this causes broken subGraph node references
- Use `semver.compare()` not string comparison for version ordering
- Mutate versions array only via Immer `produce()` (templates.ts uses this pattern throughout)
- `serializeProject()` / `deserializeProject()` from `@ironclad/rivet-core` — required for blob storage and metadata extraction
- Ownership verification required on all write endpoints: check `template.author !== session.user.id`

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
