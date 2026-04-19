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
- `packages/app/src/components/community/CommunityOverlay.tsx` — nav shell; `ts-pattern` `match()` on local `selectedNav` state; `NeedsProfile` wrapper returns `null` while login state is `undefined`
- `packages/app/src/components/community/CommunityTemplatesPage.tsx` — **empty placeholder**, not yet implemented
- `packages/app/src/components/community/EditTemplatePage.tsx` — template management; save/unpublish in `EditTemplateVersionPage` are **not yet wired**
- `packages/app/src/hooks/useUploadNewTemplate.ts` — two-step: POST `/templates` to create, then PUT `/templates/:id/version/:version`; does **not** invalidate React Query cache on success
- `packages/app/src/hooks/useUploadNewTemplateVersion.ts` — same PUT pattern; **does** invalidate `['my-templates']` on success via `queryClient`
- `packages/app/src/hooks/useNewProjectFromTemplate.ts` — deserializes, remaps all graph IDs, assigns new `ProjectId` via `nanoid()`
- `packages/app/src/utils/getCommunityApi.ts` — `getCommunityHost()` throws `'Not implemented yet'` in production mode; dev hardcodes `http://localhost:3000`
- `packages/app/src/utils/communityApi.ts` — `@recoiljs/refine` checker types for all request/response shapes
- `packages/community/src/lib/templates.ts` — Vercel KV + Blob storage; `templateParameters` and `canBeNode` are stubbed (always `{}` / `false`)
- `packages/community/src/app/api/cors.ts` — two CORS modes: GET uses public wildcard headers; mutations use `getRestrictedAccessControlHeaders()` restricted to `tauri://localhost` and `http://localhost:5173`

## Key Concepts
- **Auth:** GitHub OAuth via NextAuth + custom KV adapter; session in cookies (30-day DB sessions); all protected fetches need `credentials: 'include'`
- **KV keys:** `graph:{id}`, `graph:{id}:stars` (Redis Set via `kv.sadd/scard`), `user:{id}`, `user:email:{email}`, `user:github:{githubId}`
- **Version ordering:** versions array sorted by `semver.compare()` on write; never use string sort
- **React Query cache keys:** `['community-profile']` (login state), `['my-templates']` (user's templates) — invalidate after mutations
- **Metadata extraction:** server calls `deserializeProject()` on upload to extract node count, inputs/outputs, graph names — client sends `plugins` array separately

## Critical Rules
- All fetch calls to community API must include `credentials: 'include'` or protected endpoints return 401
- New write API routes need `export { OPTIONS }` from `cors.ts` and must use `getRestrictedAccessControlHeaders()` — without this, Tauri CORS preflight fails
- When instantiating templates via `useNewProjectFromTemplate`, remap all graph IDs — both `subGraph` and `loopUntil` node types reference other graph IDs and will break if not remapped
- Mutate versions array only via Immer `produce()` (templates.ts uses this pattern throughout)
- `serializeProject()` / `deserializeProject()` from `@ironclad/rivet-core` — required for blob storage and metadata extraction
- Ownership verification required on all write endpoints: check `template.author !== session.user.id`

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
