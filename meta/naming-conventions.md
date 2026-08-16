# Naming Conventions

Rules for files and folders managed by this library. Future Codex/AI agents must
follow these when adding, renaming, or moving documents.

## File names (Markdown)

```text
lowercase-kebab-case.md
```

- lowercase only;
- hyphen `-` only, never underscore `_`;
- no spaces;
- ASCII characters preferred;
- acronyms are lowercased: `seo`, `gsc`, `cms`, `api`, `ai`, `tmux`, `codex`,
  `nextjs`, `supabase`;
- no prefixes like `ISSUE_`, `DOC_`, `FILE_` when the folder/category already
  expresses the meaning;
- keep numbers only when they carry real meaning (for example `22` in
  `agile-scrum-22-interview-questions.md`).

## Folder names

```text
lowercase-kebab-case/
```

Category folders live under `docs/`. Existing categories: `ai-agents`,
`architecture`, `deployment`, `interview`, `seo`, `guides`. Add a new category
only when none of the existing ones truly fits; do not create empty folders.

## Project-specific documents

When a document is specific to one project, prefix the filename with the
project name:

```text
feaon-native-admin-cms-architecture.md
feaon-production-seo-gsc-analytics-ads-tech-check-plan.md
```

Generic, reusable documents do not need a project prefix.

## Examples

```text
GOOD
chatgpt-codex-collaboration-playbook.md
feaon-production-seo-gsc-analytics.md
web-application-deployment-runbook.md
supabase-nextjs-coding-agent-guide.md
agile-scrum-22-interview-questions.md

BAD
CHATGPT_CODEX_PLAYBOOK.md
Seo Guide.md
quy_trinh_deploy_v2_FINAL.md
ISSUE_A-native-admin-cms-architecture.md
```

## Adding a document

1. Read the document content first; never classify by filename alone.
2. Choose the matching category folder in `docs/`.
3. Name the file with `lowercase-kebab-case.md`.
4. Add one row to `docs/index.md`.
