# Issue A — Define Native Admin CMS Architecture

## Suggested title

```text
docs: define native admin CMS architecture
```

## Goal

Establish the canonical architecture and phased implementation plan for the
Native Feaon Admin CMS before any CMS application code or hosted Supabase
mutation begins.

## Context

Feaon already uses Supabase Database and Storage as the production source of
truth for managed content and durable lead data. The repository owns routes,
React components, schemas, validation, migrations, tests, and presentation
behavior.

The new approved direction is to add a native `/admin` CMS inside the existing
Next.js application. The CMS must operate on the existing Supabase content model
rather than introduce a second CMS platform or database.

This Issue is documentation-only.

## Scope

Create:

- `docs/superpowers/specs/2026-08-10-admin-cms-design.md`
- `docs/superpowers/plans/2026-08-10-admin-cms.md`

Update:

- `docs/ai/CURRENT_STATE.md`

The canonical design must define at minimum:

- `/admin` as a non-localized route;
- Supabase Auth session architecture;
- owner/editor/viewer role model;
- `admin_memberships`;
- database-enforced RBAC/RLS;
- ordinary CMS CRUD through user-scoped Supabase sessions;
- service-role as system-only;
- schema-driven page editing rather than a generic page builder;
- VI/EN editing behavior;
- draft/published/archived workflow;
- Pages, Blog, Case Studies, Media, Revisions, Leads and Settings modules;
- optimistic concurrency protection;
- publication revalidation;
- admin noindex/private-cache requirements;
- production safety and rollout gates;
- future AI features as a later non-MVP phase.

The master plan must split implementation into independently reviewable phases
and Pull Requests.

## Historical-doc rule

Do not rewrite historical Supabase migration documents to make them appear to
have always included a CMS.

The new CMS design supersedes only the historical custom-CMS non-goal while
preserving the existing source-of-truth architecture.

## Out of Scope

Do not:

- implement `/admin`;
- add dependencies;
- add Supabase Auth code;
- add or modify database migrations;
- change RLS;
- modify public route behavior;
- modify deployment;
- access hosted Supabase;
- change production secrets;
- create production users;
- perform any hosted mutation.

## Acceptance Criteria

- [ ] Canonical CMS design exists under `docs/superpowers/specs/`.
- [ ] Canonical master implementation plan exists under `docs/superpowers/plans/`.
- [ ] `docs/ai/CURRENT_STATE.md` names Native Feaon Admin CMS as the current initiative.
- [ ] The architecture preserves Supabase as runtime content source of truth.
- [ ] The architecture preserves Git/repository ownership of application structure.
- [ ] The architecture defines `/admin` outside the VI/EN route tree.
- [ ] The architecture defines Supabase Auth + RBAC/RLS boundaries.
- [ ] The architecture clearly separates user-scoped CMS clients from service-role.
- [ ] The architecture defines schema-driven editors and rejects a generic page builder as MVP scope.
- [ ] The plan separates foundation, pages, blog/case studies, media/revisions, operations and hardening.
- [ ] Hosted changes are explicitly out of scope.
- [ ] Historical canonical documents remain intact.
- [ ] No `.superpowers/sdd/` or `.gitnexus/` generated data is committed.

## Verification

Documentation-only verification should include:

```bash
git diff --check
git status --short
```

Also inspect:

- Markdown paths and links;
- consistency with `AGENTS.md`;
- consistency with current `docs/ai/CURRENT_STATE.md`;
- no accidental executable-code or dependency change;
- no secrets or environment values;
- no generated GitNexus or `.superpowers/sdd` files.

Application build/test may be skipped because this Issue must not change
executable behavior. Record skipped checks in the PR.

## Pull Request

Suggested PR title:

```text
docs: define native admin CMS architecture
```

The PR must:

- close this Issue;
- list the exact three documentation files changed;
- summarize the architecture decision;
- note that no hosted system was mutated;
- state that Phase 1 requires a new Issue;
- include GitNexus impact analysis or explain why a documentation-only change did
  not require graph refresh.

## Recommended Next Issue After Merge

```text
feat(admin): establish secure CMS foundation
```

That future Issue should implement only Phase 1 from:

- `docs/superpowers/specs/2026-08-10-admin-cms-design.md`
- `docs/superpowers/plans/2026-08-10-admin-cms.md`
