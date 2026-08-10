# Workflow Playbooks

Personal engineering workflow and operational playbook library.

This repository stores reusable workflows, guides, architecture notes,
deployment runbooks, AI-agent playbooks, SEO procedures, and supporting skills.

Start here: [Documentation Index](./docs/index.md)

## How to find documents

Every Markdown document has an entry in [docs/index.md](./docs/index.md) with
its category, purpose, and when to use it. Use **Quick Navigation** there to
jump straight to a category.

## Main categories

| Category | What lives here | Location |
|---|---|---|
| AI Agents | AI coding-agent workflows (ChatGPT, Codex, Command Code) and agent guides | [docs/ai-agents](./docs/ai-agents/) |
| Architecture | Reusable architecture and design specs | [docs/architecture](./docs/architecture/) |
| Deployment | Deployment runbooks and SOPs | [docs/deployment](./docs/deployment/) |
| Interview | Interview preparation materials | [docs/interview](./docs/interview/) |
| SEO | SEO, Search Console, analytics, sitemap procedures | [docs/seo](./docs/seo/) |
| Skills | Tools/skills with runnable scripts or skill definitions | [skills](./skills/) |
| Templates | Templates for new documents | [templates](./templates/) |
| Meta | Library conventions and maintenance notes | [meta](./meta/) |

## Skills

- [cmdc-tmux-consult](./skills/cmdc-tmux-consult/) — safely ask Command Code
  about a repository from an idle tmux pane, with literal prompt delivery and
  completion evidence.

## Naming convention

All Markdown filenames and folders follow `lowercase-kebab-case.md`. Acronyms
are lowercased (`seo`, `gsc`, `cms`, `api`, `ai`, `tmux`, `codex`, `nextjs`,
`supabase`). Full rules and examples:
[meta/naming-conventions.md](./meta/naming-conventions.md).

## How to add a new document

1. Pick the category folder under `docs/` that fits, or add a new one only if
   none of the existing categories truly applies.
2. Start from [templates/playbook-template.md](./templates/playbook-template.md)
   and fill in Purpose, When to use, Preconditions, Workflow, Validation,
   Troubleshooting, and References.
3. Name the file `lowercase-kebab-case.md` (see
   [naming conventions](./meta/naming-conventions.md)).
4. Add one row to [docs/index.md](./docs/index.md) with category, purpose, and
   when to use it.
