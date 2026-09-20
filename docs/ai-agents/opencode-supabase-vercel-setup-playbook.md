# OpenCode Supabase and Vercel Setup Playbook

> Last verified: 2026-09-20 with OpenCode `v2.0.10` and Vercel CLI
> `59.1.4`. Re-run the preflight commands before using version-sensitive syntax.

## Purpose

Configure OpenCode for a repository that uses Supabase and Vercel without
overwriting existing agent configuration or granting unnecessary production
access. The playbook separates stable safety rules from CLI commands that can
change between releases.

The target state is:

- OpenCode keeps all existing project instructions and configuration;
- Supabase MCP is project-scoped, read-only by default and limited to required
  feature groups;
- Vercel MCP is scoped to the intended team and project;
- browser OAuth remains an explicit owner checkpoint;
- production, domain, DNS, environment and destructive mutations require fresh
  human approval;
- optional agent skills are selected for the repository instead of installing
  an entire collection automatically.

## When to use

- Onboard an existing repository to Supabase MCP and Vercel MCP in OpenCode.
- Audit a setup that may point at the wrong account, team or project.
- Migrate an older OpenCode configuration to current CLI syntax.
- Prepare a reusable handoff between a repository owner and a coding agent.

Do not use this playbook to deploy production, change hosted data or manage
domains. It configures local developer tooling and verifies access boundaries.

## Preconditions

Collect these inputs without putting credentials in the document or Git:

| Input | Requirement | Safe source |
|---|---|---|
| Repository path | Exact local checkout | Current shell or workspace |
| Supabase project ref | Development or non-production project | Supabase dashboard URL |
| Vercel team slug | Intended account or team | Vercel dashboard or CLI |
| Vercel project slug | Existing intended project | Vercel dashboard or CLI |
| Authorization boundary | Allowed inspect/write/deploy actions | Repository instructions and owner |

Required local capabilities:

- OpenCode installed and able to start in the repository;
- a browser available for interactive OAuth;
- Git available for diff and status checks;
- Vercel CLI installed if the workflow needs CLI account or project discovery;
- access to the intended Supabase and Vercel accounts.

Never collect database passwords, service-role keys, personal access tokens or
OAuth cookies as playbook inputs.

## Stable safety rules

Apply these rules even if product commands or config schemas change:

1. Read repository instructions and existing configuration before changing it.
2. Merge the smallest required keys. Never replace a whole config file.
3. Preserve unrelated plugins, MCP servers, permissions, agents, models,
   instructions and commands.
4. Scope each remote MCP server to the intended project when the provider
   supports project scoping.
5. Use a development project and read-only mode for routine work.
6. Limit feature groups and tools to the current task.
7. Keep interactive tool-call approval enabled unless a separately reviewed
   automation needs a narrow allowlist.
8. Store OAuth state in the client's auth store, not in tracked config.
9. Treat production access and hosted mutations as separate approvals.
10. Verify account identity, project identity and Git diff before completion.

Read-only is a database guardrail, not a complete authorization model. It does
not replace tenant isolation, Row Level Security (RLS), tool approval or review
of returned data.

## Responsibility split

| Activity | Agent can perform | Owner checkpoint |
|---|---|---|
| Inspect repository and config | Yes | No |
| Run version and help commands | Yes | No |
| Prepare a minimal config diff | Yes | Review before sensitive expansion |
| Open OAuth flow | Agent may start it | Owner signs in and confirms account |
| Select Supabase project | Agent can recommend | Owner confirms correct non-production project |
| Install global plugin or skills | Only with installation authorization | Owner approves scope and package source |
| Inspect MCP connection status | Yes | No |
| Production deployment or promotion | No implicit authority | Explicit approval immediately before action |
| Change production env, domain or DNS | No implicit authority | Explicit approval immediately before action |
| Delete projects, deployments or data | No implicit authority | Explicit approval immediately before action |

## Workflow

### Phase 0: inspect repository state

Start from the repository root:

```bash
pwd
git status --short --branch
find . -maxdepth 2 \
  \( -name 'AGENTS.md' -o -name 'opencode.json' -o -name 'opencode.jsonc' \) \
  -print
```

Read every discovered instruction and config file. Also inspect `.opencode/`
when it exists. Determine:

- which config files OpenCode loads for this repository;
- whether Supabase or Vercel MCP already exists;
- whether local instructions impose stricter permissions;
- whether the repository is already linked to a Vercel project;
- whether uncommitted work must be preserved.

Stop if the existing config cannot be understood without guessing. Do not
normalize, reorder or reformat unrelated keys.

### Phase 1: capture the live CLI surface

Run help before copying commands from an older handoff:

```bash
opencode --version
opencode plugin --help
opencode plugin add --help
opencode mcp --help
opencode mcp auth --help
vercel --version
```

Record versions in the completion report. The examples below match OpenCode
`v2.0.10`. If local help disagrees, use local help and current official docs,
then update this playbook in a separate reviewed change.

Do not use removed commands such as `opencode mcp debug`. In OpenCode
`v2.0.10`, the MCP surface contains `list`, `add`, `auth` and `logout`.

### Phase 2: install or verify the Supabase plugin

First inspect installed plugins:

```bash
opencode plugin list
```

For OpenCode `v2.0.10`, install the package globally with:

```bash
opencode plugin add opencode-supabase
```

Installation changes global OpenCode state. Run it only when the package is
missing and the owner authorized installation.

The plugin bundles Supabase-related agent skills. Do not install duplicate
copies unless the plugin's current documentation requires it.

After installation, start OpenCode in the project and run:

```text
/supabase
```

The owner completes browser authentication and confirms the expected Supabase
account. Plugin authentication and project-scoped Supabase MCP are separate
layers; successful `/supabase` login does not prove the MCP target is correct.

### Phase 3: choose the Supabase MCP boundary

For routine development, select:

- the intended development or non-production project;
- `project_ref` for project scoping;
- `read_only=true` unless the current task requires writes;
- only required feature groups;
- manual approval for tool calls.

Current Supabase feature-group names include `database`, `docs`, `debugging`,
`development`, `functions`, `branching`, `account` and `storage`. Project-scoped
mode disables account-management tools. Storage is not enabled by default.
Always confirm the current list in Supabase documentation.

A narrow read-only URL can look like:

```text
https://mcp.supabase.com/mcp?project_ref=project_ref_here&read_only=true&features=database%2Cdocs
```

Prefer the configuration prompt generated by Supabase Studio when using the
plugin workflow:

1. Ask the plugin to connect the current repository to Supabase MCP.
2. In Supabase Studio, confirm the project name and project ref.
3. Enable read-only mode and the minimum feature groups.
4. Copy the generated OpenCode prompt.
5. Return to OpenCode and switch to a mode allowed to edit config.
6. Paste the generated prompt and review the proposed file change.
7. Reject the change if it replaces unrelated config.

Production access is an exception, not a default. If a task needs production
evidence, require explicit scope, project confirmation, read-only mode,
restricted features and the narrowest query that can answer the question.
Production writes remain a separate guarded operation.

### Phase 4: discover the Vercel account and project

Verify the CLI identity and available scopes:

```bash
vercel whoami
vercel teams list
vercel project list
```

When several scopes exist, pass the intended scope explicitly to project
discovery:

```bash
vercel project list --scope team_slug_here
```

Compare CLI results with the Vercel dashboard. Do not infer that a repository
name, GitHub organization or local directory equals the Vercel team or project
slug.

If the intended Vercel project does not exist, stop and obtain authorization
before creating or linking one. Project creation and `vercel link` change
external or local state and are not implied by a request to inspect setup.

### Phase 5: merge project-scoped MCP configuration

Use the official project-scoped Vercel endpoint:

```text
https://mcp.vercel.com/team_slug_here/project_slug_here
```

The logical target is two remote MCP entries inside the existing config:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "supabase": {
      "type": "remote",
      "url": "https://mcp.supabase.com/mcp?project_ref=project_ref_here&read_only=true&features=database%2Cdocs",
      "enabled": true
    },
    "vercel": {
      "type": "remote",
      "url": "https://mcp.vercel.com/team_slug_here/project_slug_here",
      "enabled": true
    }
  }
}
```

This example shows only the keys owned by this setup. Merge them into the
existing document. Do not copy the example over a real config.

OpenCode schemas can change between major versions. Preserve the active
schema's exact key names, including `plugin` versus `plugins`, rather than
silently migrating unrelated configuration during MCP setup.

Review the diff before authentication:

```bash
git diff -- opencode.json opencode.jsonc
git status --short
```

The diff must not contain tokens, credentials, `.env` values or unrelated
permission changes.

### Phase 6: authenticate remote MCP servers

Close the active OpenCode session if the client version requires a restart,
then run:

```bash
opencode mcp auth supabase
opencode mcp auth vercel
```

The owner completes each browser flow and confirms the displayed account. Do
not paste callback URLs, cookies or OAuth tokens into Git, chat or reports.

Restart OpenCode from the repository root and inspect status:

```bash
opencode mcp list
```

Expected logical result:

```text
supabase  connected
vercel    connected
```

Treat the exact formatting as version-specific. The required evidence is that
both configured names are present and connected to the intended targets.

### Phase 7: install optional Vercel skills selectively

MCP connectivity does not require installing every Vercel skill. Discover the
current packages first:

```bash
npx skills add vercel/vercel --list
npx skills add vercel-labs/agent-skills --list
```

Select only skills used by the repository. For example, a Next.js application
may need CLI guidance, deployment workflow and React performance guidance:

```bash
npx skills add vercel/vercel \
  --skill vercel-cli \
  -g -a opencode -y

npx skills add vercel-labs/agent-skills \
  --skill deploy-to-vercel \
  --skill vercel-react-best-practices \
  -g -a opencode -y
```

Installing globally changes every OpenCode workspace for the current user.
Prefer project scope when the skill is repository-specific. Do not install
React Native, design or token-auth skills only to satisfy a frozen checklist.

### Phase 8: verify permissions and negative boundaries

Verify both positive and negative expectations:

- OpenCode starts inside the repository.
- Existing instructions and unrelated config remain unchanged.
- Supabase points to the intended project ref.
- Read-only and feature restrictions match the approved task.
- Vercel points to the intended team and project slugs.
- No production deployment, promotion, rollback or mutation occurred.
- No domain, DNS or production environment variable changed.
- No secret appears in tracked files or the staged diff.

Connection success proves transport and OAuth only. It does not prove the
server points to the intended project. Verify identity and scope separately.

## Configuration merge rules

Use these rules when an agent edits `opencode.json` or `opencode.jsonc`:

1. Parse or carefully inspect the existing structure before editing.
2. Own only the `mcp.supabase` and `mcp.vercel` entries approved for this setup.
3. Preserve comments when the file uses JSON with Comments (JSONC).
4. Preserve unrelated array order and permission rules.
5. Avoid a formatter that rewrites the entire file.
6. Show the exact diff before commit.
7. Stage explicit paths only.

If both `opencode.json` and `opencode.jsonc` exist, determine precedence from
current OpenCode documentation before editing either file. Do not update both
to make them look consistent without knowing which one is authoritative.

## Production and destructive-operation gates

Require explicit approval immediately before:

- connecting broad Supabase production access;
- applying SQL, migrations or data updates to a hosted project;
- deploying or promoting a Vercel production deployment;
- rolling back production;
- adding, modifying or removing production environment variables;
- attaching, removing or changing domains;
- changing DNS;
- deleting projects, deployments, branches, databases, buckets or other
  hosted resources;
- performing an action whose production impact is unclear.

Approval for local setup, OAuth or read-only inspection does not authorize any
item in this list.

## Validation

### Repository checks

- [ ] Repository instructions were read before editing.
- [ ] Original working-tree state was captured.
- [ ] Config was merged instead of overwritten.
- [ ] Only approved config paths changed.
- [ ] Comments and unrelated permissions remain intact.
- [ ] `git diff --check` passes.

### OpenCode checks

- [ ] OpenCode version and relevant help output were captured.
- [ ] Supabase plugin is present only once.
- [ ] OpenCode starts from the repository root.
- [ ] `opencode mcp list` shows both configured servers.

### Supabase checks

- [ ] Project name and ref match the intended environment.
- [ ] Routine development does not point to production.
- [ ] Read-only mode is enabled unless a write task was separately approved.
- [ ] Feature groups are limited to the task.
- [ ] OAuth completed under the intended account.

### Vercel checks

- [ ] `vercel whoami` matches the intended account.
- [ ] Team and project slugs were independently confirmed.
- [ ] MCP uses the project-scoped endpoint.
- [ ] OAuth completed under the intended account.
- [ ] No deployment or project link was created implicitly.

### Security checks

- [ ] No token, cookie, password, service-role key or `.env` value is in Git.
- [ ] No OAuth callback data is in the report.
- [ ] No production or destructive action ran without fresh approval.
- [ ] Manual tool-call approval remains enabled unless a narrow alternative was
  explicitly reviewed.

## Completion report

Report:

1. repository and branch inspected;
2. OpenCode and Vercel CLI versions;
3. exact files changed;
4. plugin and optional skills installed, including global or project scope;
5. whether the repository was already linked to Vercel;
6. non-secret Supabase project identity and whether MCP is read-only;
7. non-secret Vercel team and project identity;
8. summarized `opencode mcp list` status;
9. manual OAuth steps still pending;
10. skipped steps and reasons;
11. `git status --short` summary;
12. confirmation that no secret, production deployment or destructive mutation
    occurred.

Do not paste raw auth logs if they may include callback URLs, identifiers not
needed by the report or credential material.

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| `opencode plugin` syntax differs from this guide | OpenCode major version changed | Run `opencode plugin --help` and current official docs; do not guess flags |
| Supabase plugin is installed but `/supabase` is missing | OpenCode session predates installation or plugin failed to load | Restart OpenCode, run `opencode plugin list`, then inspect debug logs without exposing auth data |
| OAuth browser does not open | Headless/remote environment or callback issue | Copy only the public authorization URL to an owner-controlled browser; never share callback tokens |
| Supabase auth succeeds but tools target the wrong project | OAuth account and MCP project scope are separate | Recheck `project_ref`, project name and generated Studio config |
| Supabase exposes more tools than expected | Feature groups were omitted or too broad | Set an explicit `features` list and reconnect |
| MCP shows unauthorized | OAuth state missing, expired or belongs to another account | Run `opencode mcp logout server_name_here`, then authenticate under the intended account |
| MCP server is missing from `list` | Config file not loaded or entry malformed | Confirm config discovery, current schema and repository root |
| Vercel project tools request team/project every time | Generic endpoint used | Replace it with the confirmed project-scoped endpoint |
| Vercel CLI and MCP show different accounts | Separate auth stores or scopes | Stop, identify both accounts and re-authenticate before continuing |
| Config diff rewrites unrelated sections | Formatter or whole-file replacement | Restore only the unrelated formatting changes and apply a surgical merge |
| Newly installed skills do not appear | Wrong install scope or stale session | Inspect install location and restart OpenCode |

For OpenCode `v2.0.10`, enable diagnostic output with global flags such as
`--print-logs` and `--log-level debug` on the command that fails. Sanitize logs
before sharing them.

## References

- [OpenCode plugin management](https://opencode.ai/v2/docs/plugins)
- [OpenCode MCP servers](https://opencode.ai/v2/docs/mcp-servers)
- [OpenCode CLI commands](https://opencode.ai/v2/docs/cli/commands/)
- [Supabase MCP server](https://supabase.com/docs/guides/ai-tools/mcp)
- [Supabase OpenCode plugin](https://github.com/supabase-community/opencode-supabase)
- [Vercel MCP server](https://vercel.com/docs/agent-resources/vercel-mcp)
- [Vercel CLI](https://vercel.com/docs/cli)
- [Agent Skills CLI](https://github.com/vercel-labs/skills)
