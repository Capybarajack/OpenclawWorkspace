# Skills Index (Atomic + Category Naming + Router Layer)

This repo uses three rules:

1. **Atomic skills**: keep each skill focused and independently triggerable.
2. **Category naming**: use category-prefixed router skills for discovery.
3. **Router layer**: use playbook/router skills to select the most specific atomic skill.

---

## Router Layer (start here when scope is broad)

- `frontend-ui-playbook` → route UI/UX + design-system style tasks
- `frontend-vue-playbook` → route Vue ecosystem tasks
- `frontend-react-playbook` → route React ecosystem tasks
- `backend-node-playbook` → route Node.js backend architecture tasks

---

## Frontend / UI

- `frontend-design`
- `ui-ux-pro-max`
- `tailwind-design-system`
- `react-best-practices`
- `webapp-testing`

## Frontend / Vue

- `vue-best-practices`
- `vue-debug-guides`
- `vue-jsx-best-practices`
- `vue-options-api-best-practices`
- `vue-pinia-best-practices`
- `vue-router-best-practices`
- `vue-testing-best-practices`
- `create-adaptable-composable`
- `supabase-vue`

## Backend / Node

- `nodejs-backend-patterns`

## Full-stack / Product Integrations

- `google-auth-nuxt-supabase`
- `supabase-nuxt-db-storage`

## Data / API / Domain

- `markitdown`
- `steam-web-api-docs`
- `spec-kit`
- `tdx-bus-samplecode`
- `BusStatus`

## Orchestration / Ops

- `team-tasks`
- `team-tasks-hybrid`
- `telegram-retry-guard`
- `openclaw-memory-janitor`
- `memory-lancedb-pro`
- `codex-openclaw-shared-lancedb`
- `codex-official`
- `capyopenclaw`
- `claude-skill-building-playbook`
- `trellis-2`

---

## Maintenance rules

- Add new skills as atomic folders first.
- If multiple atomic skills overlap in one domain, add/update one router skill instead of merging atomic skills.
- Keep router SKILL.md short and selection-focused; keep deep details in atomic skills.
