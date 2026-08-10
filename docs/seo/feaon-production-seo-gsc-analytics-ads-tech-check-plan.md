# Feaon Production SEO, Search Console, Analytics & Ads Tech-Check Plan

**Repository:** `Akbi47/Feaon-ldp-v2`\
**Baseline:** after PR #28 merge (`a5e0ffadd30bf8e09da3d15d7858a58798e97973`)\
**Purpose:** provide a durable, executable handoff for Codex to verify production SEO, prepare Search Console/analytics/Ads measurement work, and stop at the correct human-only boundaries.

---

## 0. Execution Contract

This plan is intentionally split between:

- **CODEX-CAN-DO**: repository inspection, read-only live-site checks, local commands, tests, issue/PR implementation, documentation updates, and evidence collection.
- **HUMAN-ONLY**: actions requiring account ownership, DNS changes, hosted Google product configuration, production secrets, billing, campaign activation, or final merge/deploy authority.

Codex must **not**:

- change DNS records;
- log into or configure Google Search Console;
- create or modify Google Analytics / Google Tag Manager / Google Ads accounts;
- create or enable Google Ads campaigns;
- read, print, stage, or commit production secrets, real API keys, verification tokens, PEM files, environment values, account IDs, or customer data;
- mutate production Supabase content/schema unless an explicitly scoped Issue authorizes it;
- broaden task scope beyond the active Issue;
- merge its own PR without human approval unless explicitly instructed by the repository owner.

### Source of truth

Before any SEO/measurement work, read in this order:

1. active GitHub Issue;
2. `AGENTS.md`;
3. `README.md`;
4. `docs/ai/CURRENT_STATE.md`;
5. `docs/SEO.md`;
6. relevant specs/plans;
7. source/tests.

`docs/SEO.md` is the current durable SEO/measurement operations guide.

---

# Phase 1 — Synchronize and Confirm Repository Baseline

## Goal

Ensure local work starts from the merged SEO documentation state.

## CODEX-CAN-DO

Run:

```bash
git checkout main
git pull origin main
git status --short
git log -1 --oneline
```

Expected baseline should be PR #28 merge or a newer approved commit.

Known merge commit at time of this plan:

```text
a5e0ffadd30bf8e09da3d15d7858a58798e97973
Merge pull request #28 from Akbi47/docs/issue-27-seo-guide
```

### PASS criteria

- working tree is clean;
- branch is `main`;
- local `main` is up to date with `origin/main`;
- `docs/SEO.md` exists;
- `README.md` links to `docs/SEO.md`.

### FAIL action

Stop and report the exact mismatch. Do not reset, force-push, or discard local work without explicit approval.

---

# Phase 2 — Production Live SEO Audit

## Goal

Verify that the deployed `https://feaon.com` output matches the repository SEO contract before configuring Search Console or Ads measurement.

This phase is read-only.

## 2.1 HTTP / canonical-host checks

Run:

```bash
curl -I https://feaon.com
curl -I http://feaon.com
curl -I https://www.feaon.com
```

### Expected

```text
https://feaon.com       -> 200
http://feaon.com        -> redirect to canonical HTTPS origin
www.feaon.com           -> consistent redirect/canonical handling
```

### Flag as FAIL if

- canonical HTTPS root is not reachable;
- redirect loops exist;
- unnecessary multi-hop redirect chains exist;
- production serves a non-canonical host as an independent 200 page.

Record actual status codes and `Location` headers.

---

## 2.2 Production crawl contract

Repository contract:

```text
NODE_ENV=production
NEXT_PUBLIC_SITE_URL=https://feaon.com
```

Codex must **not read or print production environment secrets**.

Verification must be based on observable production output and safe config names only.

---

## 2.3 Robots check

Run:

```bash
curl -s https://feaon.com/robots.txt
```

Expected production behavior should include crawling and the production sitemap, equivalent to:

```text
User-agent: *
Allow: /

Sitemap: https://feaon.com/sitemap.xml
```

### BLOCKER

If production returns:

```text
Disallow: /
```

or pages emit `noindex`, stop the Search Console sequence.

Likely cause: the canonical production crawl contract is not satisfied.

Do **not** weaken `isPublicProduction()` to work around a deployment misconfiguration.

---

## 2.4 Sitemap check

Run:

```bash
curl -fsSL https://feaon.com/sitemap.xml | head -100
```

Verify that canonical pages are present, including representative routes such as:

```text
https://feaon.com/
https://feaon.com/en
https://feaon.com/gioi-thieu
https://feaon.com/en/about
```

Verify dynamic/service/blog/case-study routes are represented as appropriate.

### Must NOT appear as canonical sitemap entries

```text
https://feaon.com/dich-vu
https://feaon.com/en/services
```

These are redirect-only roots.

### Important registry rule

Current implementation behavior:

- `STATIC_ROUTE_DEFS` exposes and propagates `sitemap`;
- `CATEGORY_ROUTE_DEFS` is mapped with `sitemap: true`;
- `SERVICE_ROUTE_DEFS` is mapped with `sitemap: true`.

Do not assume `sitemap: false` works for category/service definitions without a separate implementation change and tests.

---

## 2.5 Route metadata checks

Run representative checks:

```bash
curl -fsSL https://feaon.com/gioi-thieu \
  | grep -oiE '<title>[^<]*|canonical[^>]*|hreflang[^>]*|robots[^>]*|og:url[^>]*'

curl -fsSL https://feaon.com/en/about \
  | grep -oiE '<title>[^<]*|canonical[^>]*|hreflang[^>]*|robots[^>]*|og:url[^>]*'
```

Expected examples:

### Vietnamese

```text
canonical = https://feaon.com/gioi-thieu
hreflang vi = https://feaon.com/gioi-thieu
hreflang en = https://feaon.com/en/about
```

### English

```text
canonical = https://feaon.com/en/about
hreflang vi = https://feaon.com/gioi-thieu
hreflang en = https://feaon.com/en/about
```

### FAIL conditions

- `noindex` on canonical production;
- child page canonical points to `/` or `/en`;
- missing or 404 hreflang sibling;
- VI/EN canonical cross-wired;
- Open Graph URL disagrees with canonical.

---

## 2.6 Representative-route matrix

Inspect at least:

```text
/
/en

/gioi-thieu
/en/about

/lien-he
/en/contact

/blog
/en/blog

/dich-vu/thiet-ke-web
/en/services/web-design

1 VI/EN blog-post pair with localized slugs
1 VI/EN case-study pair with localized slugs

/chinh-sach-bao-mat
/en/privacy

/sitemap.xml
/robots.txt
```

For each page record:

- HTTP status;
- `<html lang>`;
- title;
- meta description;
- robots meta;
- canonical;
- hreflang;
- Open Graph URL/locale/image;
- H1 count/ownership where practical;
- JSON-LD presence/type;
- redirect behavior if applicable.

---

## 2.7 Structured-data checks

Confirm representative page types:

```text
Homepage     -> Organization + WebSite
Service      -> Service
Blog post    -> BlogPosting
Author       -> Person
Case study   -> CreativeWork
Hierarchy    -> BreadcrumbList
```

Structured data must:

- use canonical localized URLs;
- describe visible content only;
- not invent ratings, prices, addresses, authors, or organization facts.

---

## 2.8 Phase 2 PASS gate

Do not proceed to Search Console until all of these are true:

```text
canonical production HTTPS root reachable      PASS
robots.txt allows crawling                     PASS
production pages do not emit noindex           PASS
sitemap.xml returns 200                        PASS
redirect-only roots absent from sitemap        PASS
canonical URLs correct                         PASS
VI/EN hreflang correct                         PASS
representative JSON-LD present                 PASS
representative routes return intended status   PASS
```

### Deliverable

Create a concise audit report in the active Issue/PR or local notes containing:

- command;
- expected;
- actual;
- PASS/FAIL;
- blocker classification.

Do not open a runtime fix PR unless an Issue is created/approved for the discovered defect.

---

# Phase 3 — Google Search Console Operational Setup

## Goal

Register the production site with Search Console only after Phase 2 passes.

## HUMAN-ONLY

### 3.1 Create Search Console property

Create a **Domain Property**:

```text
feaon.com
```

Do not enter:

```text
https://feaon.com
www.feaon.com
feaon.com/
```

Domain Property is preferred because it covers protocols and subdomains.

---

## HUMAN-ONLY

### 3.2 DNS verification

Google will provide a TXT verification value similar to:

```text
google-site-verification=...
```

Add it at the authoritative DNS provider.

Do not commit or paste the real verification token into the repository.

Verify ownership in Search Console.

---

## HUMAN-ONLY

### 3.3 Submit sitemap

In:

```text
Search Console
-> Indexing
-> Sitemaps
```

Submit:

```text
sitemap.xml
```

Expected:

```text
Status: Success
```

### STOP condition

If Search Console reports:

```text
Couldn't fetch
```

return to Phase 2 and diagnose:

- HTTP status;
- TLS;
- robots;
- sitemap response;
- canonical host;
- firewall/CDN behavior.

Do not continue by repeatedly resubmitting a broken sitemap.

---

## HUMAN-ONLY

### 3.4 URL Inspection

Use **Test live URL** for:

```text
https://feaon.com/
https://feaon.com/en
one VI/EN static pair
one VI/EN service pair
one VI/EN blog-post pair
one VI/EN case-study pair
```

Confirm:

```text
Page fetch: Successful
Indexing allowed: Yes
```

Check Google-selected canonical versus application canonical.

---

## HUMAN-ONLY

### 3.5 Request indexing selectively

Request indexing for a small representative/high-value set only:

```text
homepage VI
homepage EN
primary service VI
primary service EN
one important VI article
one important EN article
one representative VI case study
one representative EN case study
```

Do not manually request every sitemap URL.

---

## HUMAN-ONLY

### 3.6 Ongoing Search Console monitoring

Monitor:

```text
Performance
Indexing -> Pages
Sitemaps
Core Web Vitals
Enhancements
Security & Manual Actions
```

Track separately for VI and EN when useful.

Do not treat temporary non-indexing as a code bug until technical causes are verified.

---

# Phase 4 — GA4 Basic Measurement Verification

## Goal

Confirm basic production analytics before implementing Ads conversion optimization.

Current repository supports a public GA4 measurement identifier through configuration.

## HUMAN-ONLY

Create/select the GA4 property and Web Data Stream for:

```text
https://feaon.com
```

Obtain the measurement ID in the hosted Google UI.

Do not commit production identifiers into tracked `.env` files.

---

## HUMAN + CODEX

Production environment configuration is a deployment operation and remains human-controlled.

After the deployment owner safely configures the GA measurement ID and redeploys, Codex may perform read-only verification.

### CODEX-CAN-DO

Verify production page source/network behavior and record whether the GA tag is present as expected.

Human verifies in GA4 Realtime:

```text
active user
page_view
session_start
```

### Important status distinction

```text
GA4 page/session measurement  !=  confirmed lead conversion measurement
```

At this point:

```text
basic analytics       potentially READY
lead conversions      NOT READY
Ads optimization      NOT READY
```

---

# Phase 5 — Consent & Tagging Architecture

## Goal

Create a dedicated implementation task before adding Ads/remarketing measurement.

This is not part of SEO runtime.

## Required Issue

Suggested title:

```text
feat(analytics): establish consent-aware Google measurement foundation
```

## Scope

Define one approved architecture:

```text
Option A: Google Tag Manager
Option B: direct gtag integration
```

Do not run both unmanaged paths for the same measurement because duplicate page views/conversions may result.

Issue should define:

- chosen tag architecture;
- environment/config contract using safe placeholders only;
- consent UI/CMP strategy;
- Consent Mode integration;
- default/update consent behavior;
- analytics and advertising tag behavior;
- privacy-policy update requirements;
- test/debug procedure;
- rollback;
- production/preview behavior;
- no-secret handling.

Consent states to account for include:

```text
analytics_storage
ad_storage
ad_user_data
ad_personalization
```

## CODEX-CAN-DO after Issue approval

- implement repository code;
- add tests;
- update `.env.example` only with safe variable names/placeholders;
- update `docs/SEO.md` if the durable measurement architecture changes;
- open a PR.

## HUMAN-ONLY

- create/configure GTM/Google hosted resources;
- manage account permissions;
- set real IDs;
- approve privacy/legal copy;
- final merge/deploy.

---

# Phase 6 — Confirmed Lead Conversion Tracking

## Goal

Count a lead only when the backend confirms successful creation.

Current conceptual form flow:

```text
submit
  -> API
  -> result.ok
  -> success UI
```

Required flow:

```text
submit
  -> API
  -> result.ok
  -> emit generate_lead
  -> success UI
```

## Never count as a confirmed lead

```text
button click
form submit attempt
validation success
network request start
failed API response
```

---

## Required Issue

Suggested title:

```text
feat(analytics): track confirmed lead conversions
```

## Event contract

Recommended logical event:

```text
event: generate_lead
lead_type: contact | consultation
locale: vi | en
submission_id: stable non-PII idempotency/submission identifier
```

### Must NOT send raw PII in browser analytics payloads

```text
name
phone
email
free-text message
other form PII
```

## Required coverage

- contact form success;
- consultation form success;
- failure path emits nothing;
- retry path does not double-count;
- re-render does not double-count;
- VI/EN both work;
- consent-granted path;
- consent-denied path;
- preview/non-production behavior matches approved policy.

## Tests

At minimum verify:

```text
successful backend response -> one event
validation error            -> zero events
network error               -> zero events
backend error               -> zero events
retry                        -> max one conversion for same submission
event payload                -> no raw PII
contact                      -> lead_type=contact
consultation                 -> lead_type=consultation
```

---

# Phase 7 — Google Ads Conversion Configuration

## Goal

Connect the confirmed lead event to Ads reporting only after Phase 6 is verified.

## HUMAN-ONLY

Create/configure Google Ads conversion action in the hosted Ads account.

Choose one primary reporting path for the same logical lead:

```text
A. import GA4 generate_lead into Google Ads
OR
B. direct Google Ads conversion event
```

### Avoid

```text
GA4-imported lead = Primary
AND
direct Ads lead   = Primary
```

for the same business conversion unless the measurement architecture deliberately prevents double counting.

## Validation

Submit real controlled test leads and confirm:

```text
one successful lead -> one primary conversion
failed lead         -> zero conversions
retry               -> no duplicate conversion
```

Do not trust conversion-based bidding until this passes.

---

# Phase 8 — Marketing Attribution Persistence

## Goal

Associate campaign context with confirmed lead records so marketing performance can be evaluated beyond page views.

## Required Issue

Suggested title:

```text
feat(leads): capture marketing attribution
```

## Recommended fields

```text
utm_source
utm_medium
utm_campaign
utm_content
utm_term
gclid
gbraid
wbraid
landing_page
referrer
```

## Implementation requirements

- sanitize values;
- enforce safe length limits;
- never use attribution parameters for authorization;
- choose and document first-touch/last-touch policy;
- persist only approved fields;
- account for schema/migration impact;
- define retention/deletion implications;
- include privacy-policy review;
- preserve lead idempotency;
- do not create duplicate leads on retries.

## Expected business trace

```text
Google Ads
  -> campaign
  -> ad / keyword
  -> landing page
  -> confirmed lead
  -> lead quality / downstream outcome
```

---

# Phase 9 — Optional SEO/CMS Enhancements

These are not current launch blockers.

Only create Issues when production data or a real editorial need justifies them.

Potential tasks:

```text
default 1200x630 Open Graph image
seo_social_image field
controlled seo_indexable field
controlled canonical_override
controlled sitemap_include
redirect registry / manager
404 monitoring
editor metadata/social preview
duplicate-title reporting
richer verified Organization schema
WebPage schema graph
server pagination for large blog archives
sitemap index if URL scale grows
specialized image/video/news sitemap if justified
WOFF2 font optimization
Core Web Vitals optimization based on real data
```

High-risk editor controls must have validation, safe defaults, tests, and governance.

---

# Phase 10 — Final Launch / Scale Gate

Do not consider SEO + acquisition measurement fully operational until:

## Production SEO

```text
[ ] canonical production root works
[ ] robots allows crawling
[ ] production pages are indexable
[ ] sitemap is valid and fetchable
[ ] redirect aliases excluded
[ ] canonical correct
[ ] hreflang correct
[ ] representative JSON-LD correct
[ ] representative routes return intended status
```

## Search Console

```text
[ ] Domain Property verified
[ ] sitemap submitted successfully
[ ] representative live URL tests pass
[ ] Google-selected canonical is acceptable
[ ] indexing reports monitored
```

## Analytics

```text
[ ] basic GA4 measurement verified
[ ] no duplicate page views
[ ] production/preview behavior verified
```

## Consent

```text
[ ] consent UI/CMP approved
[ ] Consent Mode behavior tested
[ ] optional tags respect denied/granted state
[ ] privacy policy matches deployed tracking
```

## Lead conversion

```text
[ ] contact success emits one generate_lead
[ ] consultation success emits one generate_lead
[ ] failed submissions emit zero
[ ] retries are deduplicated
[ ] no raw PII in analytics payloads
```

## Google Ads

```text
[ ] one Primary conversion source chosen
[ ] controlled test conversion verified
[ ] no double counting
[ ] campaign final URLs avoid unnecessary redirects
```

## Attribution

```text
[ ] approved UTM/click identifiers captured
[ ] landing page/referrer captured
[ ] attribution policy documented
[ ] lead records remain idempotent
[ ] privacy/retention reviewed
```

Only after these gates pass should conversion-based Ads optimization or meaningful budget scaling be trusted.

---

# Codex Execution Order

Use this strict sequence:

```text
Phase 1  Repository baseline
   ↓
Phase 2  Production live SEO audit
   ↓
Phase 3  HUMAN: Search Console
   ↓
Phase 4  GA4 basic verification
   ↓
Phase 5  Issue + PR: consent-aware measurement foundation
   ↓
Phase 6  Issue + PR: confirmed generate_lead conversions
   ↓
Phase 7  HUMAN: Google Ads conversion configuration
   ↓
Phase 8  Issue + PR: campaign attribution persistence
   ↓
Phase 9  Optional SEO/CMS enhancements only when justified
   ↓
Phase 10 Final launch/scale gate
```

---

# First Codex Task

Start with **Phase 1 and Phase 2 only**.

Codex prompt:

```text
Read AGENTS.md, README.md, docs/ai/CURRENT_STATE.md, and docs/SEO.md first.

Execute Phase 1 and Phase 2 from this plan only.

Goal:
Perform a read-only production SEO audit of https://feaon.com against the
current main branch after PR #28.

Do not modify DNS, Search Console, Analytics, Ads, Supabase, deployment
configuration, environment values, secrets, or production data.

Do not implement fixes yet.

Return:
1. repository baseline;
2. live HTTP/redirect results;
3. robots result;
4. sitemap result;
5. representative canonical/hreflang/robots/OG checks;
6. representative JSON-LD checks;
7. PASS/FAIL matrix;
8. blockers classified as BLOCKER / SHOULD FIX / OPTIONAL;
9. exact proposed next Issue scope for any failure.

Stop after the audit.
```

---

# Change Policy

Whenever a future Issue changes any of the following:

```text
canonical domain
locale URL model
crawl policy
sitemap policy
SEO content schema
structured-data strategy
analytics architecture
consent behavior
conversion event contract
attribution model
```

update `docs/SEO.md` in the same PR so the durable documentation does not become stale.

Never create a second competing SEO, routing, sitemap, consent, or analytics architecture without an explicit approved Issue.
