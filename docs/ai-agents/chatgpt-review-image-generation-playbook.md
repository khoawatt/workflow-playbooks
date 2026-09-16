# Image Generation Lifecycle And Recovery Playbook

## Purpose

Use this playbook for AI image generation, recovery, validation, review, and
optional publication. It is the lifecycle source of truth for commands and
provider adapters that invoke it.

Generation and publication are separate concerns. Creating or recovering an
image does not authorize uploading it, changing references, or mutating a
hosted system.

## Core Invariants

- Submission is not completion.
- A request or bridge timeout means completion was not observed through that
  transport. It does not prove generation failure.
- `SUBMIT_UNKNOWN` is not `SUBMIT_REJECTED`.
- Once submission may have succeeded, reconcile that attempt before creating
  another generation.
- When a durable generation identifier exists, observe and recover by that
  identifier before considering resubmission.
- A rendered preview, thumbnail, or placeholder is not accepted as the
  original asset.
- Preserve the original binary where practical. Publish only an approved
  canonical artifact.
- Machine validation and visual review are distinct gates.
- Publishing and production verification require explicit task authority.

## Lifecycle

The normal lifecycle is:

```text
PREPARED
  -> SUBMITTING
  -> SUBMITTED
  -> OBSERVING
  -> ASSET_DISCOVERED
  -> ORIGINAL_VERIFIED
  -> CANONICAL_READY
  -> REVIEW_PENDING
  -> APPROVED
  -> [optional PUBLISHING]
  -> DONE
```

Exceptional states describe what is known, not merely whether a command exited
non-zero:

| State | Meaning |
|---|---|
| `SUBMIT_REJECTED` | The provider definitely rejected the request before accepting generation work. |
| `SUBMIT_UNKNOWN` | Submission may have succeeded, but acceptance or a durable identifier was not observed. |
| `GENERATION_PENDING` | A durable identifier exists and completion has not yet been observed. |
| `GENERATION_FAILED` | The provider positively reports failure or cancellation. |
| `ASSET_PREVIEW_ONLY` | A rendered candidate exists, but no original has been recovered. |
| `ASSET_FETCH_FAILED` | The original source is known, but retrieval failed. |
| `ASSET_INVALID` | The retrieved binary failed required validation. |
| `REVIEW_REJECTED` | The artifact is technically valid but failed visual or human review. |
| `PUBLISH_CONFLICT` | The publication target changed before references could be updated safely. |
| `PUBLISH_VERIFY_FAILED` | Upload or mutation occurred, but the remote artifact or production rendering is not verified. |

Do not collapse these states into a generic `failed -> retry prompt` rule.

## Prepare The Request

Record the task's actual requirements before submission:

- number of images;
- intended use and subject;
- style and composition;
- required aspect ratio or dimensions, if any;
- format constraints, if any;
- prohibited text, logos, watermarks, people, or other content;
- destination for temporary, original, and canonical artifacts;
- whether publication is authorized.

For a family of images, give each requested asset a stable logical name or
number. Provider-specific batching rules belong in the provider adapter.

Hash the exact submitted prompt with SHA-256 for provenance. A changed prompt
is a new semantic generation attempt, not a transport retry.

## Submit And Capture A Durable Identifier

Treat submission as its own event:

1. Enter `SUBMITTING` before sending the prompt.
2. If the provider definitely rejects it, record `SUBMIT_REJECTED`.
3. If accepted, capture and persist the provider's durable identifier as early
   as safely possible. Examples include conversation, generation, task, or
   request IDs.
4. Persist `SUBMITTED` before waiting for completion.
5. If submission may have succeeded but no durable identifier is observable,
   record `SUBMIT_UNKNOWN`, the last observed provider location/state, and
   `safe_to_resubmit: false`.

Do not wait for a text response before saving a durable identifier. Image-only
generation may complete without producing the text signal expected by a
request bridge.

## Observe And Recover

Observe generation independently from the request transport:

1. Reopen or query the exact durable identifier.
2. Continue bounded observation while the provider reports work in progress.
3. Account for delayed hydration, lazy loading, pagination, or repeated
   rendered nodes.
4. Discover all plausible asset sources, then deduplicate them using stable
   provider IDs, source identity, and finally binary hashes.
5. Distinguish original assets from UI previews, thumbnails, placeholders, and
   screenshots.
6. If an original requires authentication, retrieve it through the existing
   authenticated provider context rather than exporting cookies or assuming a
   displayed URL is public.

A process exit, log timeout, or missing text reply is not sufficient evidence
for `GENERATION_FAILED`.

## Validate The Original Binary

Accept an original only after the checks relevant to the task pass:

- successful authenticated retrieval when required;
- expected HTTP/content type where available;
- file signature and decoded format agree;
- the binary decodes without error;
- dimensions and aspect ratio satisfy task-supplied requirements;
- byte size is plausible for the format and task;
- SHA-256 is recorded;
- duplicate detection is performed across the current batch and existing
  accepted candidates.

Do not use one global byte threshold, dimension, or format as proof that an
asset is original. Provider and project requirements supply those constraints.

If validation fails, preserve the evidence and inspect other original
candidates before authorizing a new generation.

## Original And Canonical Artifacts

Keep these identities distinct:

```text
original provider binary
  -> optional crop, resize, color adjustment, or conversion
  -> canonical artifact
  -> preview or rendered placement
  -> optional publication
```

Preserve the original during recovery and review where practical. Record every
canonical transformation. If no transformation is needed, the original and
canonical hashes may be identical. The task—not this playbook—determines the
canonical format and dimensions.

Never silently overwrite an accepted original or canonical artifact. Use
stable paths and fail closed on unexpected existing files.

## Audit And Provenance

Maintain one audit record per logical generation attempt. JSON is recommended,
but the exact serialization is project-owned.

Minimal reusable fields:

```json
{
  "prompt_sha256": "...",
  "provider": "...",
  "durable_generation_id": "... or null",
  "submission_status": "submitted | rejected | unknown",
  "recovery_status": "pending | recovered | failed | invalid",
  "submitted_at": "ISO-8601 timestamp",
  "recovered_at": "ISO-8601 timestamp or null",
  "original": {
    "path": "...",
    "mime": "...",
    "format": "...",
    "width": 0,
    "height": 0,
    "bytes": 0,
    "sha256": "..."
  },
  "canonical": {
    "path": "...",
    "width": 0,
    "height": 0,
    "sha256": "...",
    "transformation": "none or structured metadata"
  },
  "review_status": "pending | approved | rejected",
  "publish_status": "not_requested | pending | published | failed"
}
```

The original path, canonical object, review status, and publish status may be
absent until those phases occur. Project-specific mapping, CMS, locale, issue,
and storage fields are optional extensions, not core requirements.

Write audit updates atomically when practical, especially immediately after
submission and after original recovery.

## Visual Review Gate

Binary validation does not establish visual suitability. Review the canonical
artifact against its intended placement. Depending on the task, use:

- individual local previews;
- contact sheets for a family;
- desktop and mobile rendering;
- `object-fit` or crop verification;
- subject, geometry, face, hand, and material inspection;
- unwanted text, logo, and watermark inspection;
- consistency of lighting, palette, style, and composition across a family.

Record `APPROVED` only after the required reviewer accepts the artifact. A
visual rejection authorizes no automatic regeneration unless the task permits
a new generation attempt.

## Retry And Reconciliation Matrix

| Observed condition | Required action |
|---|---|
| Submission definitely rejected before acceptance | Correct the request or transport; prompt submission may be retried. |
| Submission accepted and durable ID persisted | Resume observation/recovery by ID; do not resubmit. |
| Timeout after accepted or possibly accepted submission | Record `GENERATION_PENDING` when an ID exists, otherwise `SUBMIT_UNKNOWN`; reconcile first. |
| Generation is still pending | Continue bounded observation; do not create another generation. |
| Asset discovery is incomplete | Rehydrate, scroll, paginate, and deduplicate again. |
| Original retrieval fails transiently | Retry retrieval for the same source and generation ID. |
| Only preview candidates exist | Continue searching for an original source; do not accept the preview. |
| Retrieved asset is invalid | Preserve evidence and inspect alternate originals before regeneration. |
| Provider explicitly reports failure or cancellation | A new generation may be started when task authority permits. |
| Visual review rejects a valid artifact | Treat regeneration as a deliberate new semantic attempt. |
| Publication conflicts with newer remote state | Refetch and reconcile remote state; do not regenerate. |
| Production verification fails | Investigate upload, reference, cache, and rendering layers; do not regenerate automatically. |

Polling or re-fetching the same attempt is transport recovery. Sending the
prompt again creates new semantic work and must be treated separately.

## Optional Publishing Contract

Run this phase only when publication is explicitly authorized:

```text
approved canonical artifact
  -> upload
  -> verify remote binary and metadata
  -> refetch publication baseline
  -> update references, preferably with optimistic concurrency
  -> verify production rendering
  -> DONE
```

Upload success, reference-update success, and production rendering are three
different facts. Record each separately. On ambiguous mutation responses,
re-read state before retrying or rolling back.

## ChatGPT Web Adapter

This section is provider-specific. It does not define universal image-provider
behavior.

### Browser ownership

- Use one persistent Chromium profile owner at a time.
- Inspect the process that owns the profile and whether a CDP endpoint already
  exists before launching or attaching.
- When a browser already owns the profile, attach through Playwright
  `connectOverCDP`; do not launch another browser with the same user-data-dir.
- Do not delete Chromium `SingletonLock` files while their owner is alive.
- Do not use broad `pkill` commands. Any stale-lock recovery must be scoped to
  the exact verified profile and dead owner.
- Preserve the bridge's single-profile serialization behavior.

### Submission and observation

- Treat the ChatGPT conversation ID as the durable generation identifier.
- Persist it immediately after the conversation URL becomes observable, before
  waiting for assistant text.
- A text-oriented bridge timeout after submission is `GENERATION_PENDING` when
  the conversation ID is known, otherwise `SUBMIT_UNKNOWN`.
- Reopen the exact conversation for recovery and observe the conversation DOM.
- Current implementations may inspect image nodes within conversation turns or
  use provider-specific image attributes. Selectors are replaceable adapter
  details and must be verified against the live DOM.
- Account for hydration and lazy loading. Scroll the actual conversation
  containers and require the expected set of unique candidates before
  recovery.

### Original recovery

- Collect candidate `currentSrc`, `src`, `srcset`, picture sources, parent
  links, and stable provider file IDs when present.
- Deduplicate repeated rendered nodes before downloading.
- Prefer the provider's original asset source over screenshots or rendered
  thumbnails.
- Retrieve authenticated originals through the existing Playwright browser
  context request API. Do not export cookies or assume a signed/displayed URL
  can be fetched anonymously.
- Validate the returned binary using the generic validation phase and
  task-supplied requirements.

Headful mode may be required when provider anti-automation checks block
headless access. This is an adapter fallback, not a core invariant.

## Failure-Oriented Troubleshooting

| Symptom | Classification | Action |
|---|---|---|
| Login/session unavailable before submission | `SUBMIT_REJECTED` | Restore authentication, then submit once. |
| Send was attempted and the bridge timed out waiting for text | `GENERATION_PENDING` with ID, otherwise `SUBMIT_UNKNOWN` | Inspect saved bridge state and recover/reconcile; do not blindly resend. |
| Another live process owns the provider profile | Observation blocked, not generation failure | Wait for or attach to the verified owner; do not delete its locks. |
| Conversation opens but images are initially missing | `GENERATION_PENDING` or incomplete discovery | Wait for hydration and progressively inspect the real scroll containers. |
| Many DOM nodes reference fewer assets | Duplicate rendered candidates | Deduplicate by stable source ID and binary hash. |
| Download returns HTML, login content, or a thumbnail | `ASSET_PREVIEW_ONLY` or `ASSET_FETCH_FAILED` | Use authenticated original recovery from the same provider context. |
| Binary type, decode, dimensions, or hash checks fail | `ASSET_INVALID` | Preserve evidence and inspect alternate originals. |
| Canonical image crops badly in its component | `REVIEW_REJECTED` | Adjust the authorized canonical transformation or start a deliberate new generation. |
| Upload succeeds but the page still renders the old asset | `PUBLISH_VERIFY_FAILED` | Verify references, cache/revalidation, and the exact production route. |

## Handoff

Report at least:

- lifecycle state;
- durable generation identifier, or why none is available;
- audit record path;
- original and canonical artifact paths;
- validation result;
- review/approval status;
- publication and production-verification status when applicable;
- unresolved ambiguity and the next safe action.
