# SEO Configuration and Maintenance Guide

This document is the durable reference for SEO implementation and related
production operations in Feaon LDP. It documents the architecture established by
Issues #21-#23 and PRs #24-#26, plus the expanded documentation scope approved in
Issue #27 after review of PR #28.

The operational sections describe prerequisites and future implementation
contracts. They do not authorize changes to Search Console, DNS, Analytics,
Google Tag Manager, Google Ads, consent platforms, deployment, Supabase, or any
other hosted system. Every runtime or hosted mutation still requires its own
scoped Issue and human approval.

## Core Rules

1. Treat `lib/routes/routes.ts` as the source of truth for localized routes.
2. Build canonical URLs and language alternates through `lib/seo/site.ts`.
3. Use the shared builders under `lib/seo`; do not create parallel canonical,
   hreflang, sitemap, or structured-data logic inside individual pages.
4. Managed SEO text comes from published Supabase content translations.
5. Match dynamic VI/EN translations by stable content ID, never by assuming both
   locales use the same slug.
6. Only canonical production is indexable. Local, preview, staging, and
   misconfigured production builds fail closed to `noindex, nofollow`.
7. `app/[locale]/layout.tsx` owns `<html>`, `<body>`, and the only `<main>`
   landmark. Route pages must not add another `<main>`.
8. Search Console readiness, Analytics availability, and Ads conversion
   readiness are separate states. Do not treat one as proof of another.
9. Never commit account IDs, verification tokens, DNS records, campaign data,
   lead PII, environment values, or secrets to this guide.

## Architecture Map

| Concern | Source of truth |
| --- | --- |
| Localized route definitions | `lib/routes/routes.ts` |
| Absolute URLs and localized paths | `lib/seo/site.ts` |
| Shared metadata and fallback logic | `lib/seo/metadata.ts` |
| Static Supabase-backed metadata | `lib/seo/static-content-metadata.ts` |
| Dynamic translation mapping and article metadata | `lib/seo/dynamic-metadata.ts` |
| Structured-data builders | `lib/seo/json-ld.ts` |
| JSON-LD rendering component | `components/shared/json-ld.tsx` |
| Document language and global robots metadata | `app/[locale]/layout.tsx` |
| Sitemap generation | `app/sitemap.ts` |
| `robots.txt` generation | `app/robots.ts` |
| Environment crawl policy | `lib/config/env.ts` |
| Supabase content and SEO records | `lib/data/content-repository.ts` |
| Cached SEO/content reads | `lib/data/content-cache.ts` |
| Contact conversion success boundary | `app/[locale]/(categories)/contact/_components/ContactFormCard.tsx` |
| Consultation conversion success boundary | `components/shared/consultation-modal/_components/ConsultationModalFormPanel.tsx` |

## Current Implementation Snapshot

As of the baseline review on 2026-08-05 against `main` commit `12e7b901`:

- route-level metadata is centralized and Supabase-backed;
- canonical URLs are self-referencing and locale-aware;
- static localized alternates come from the route registry;
- blog-post and case-study translations are paired by stable content ID;
- missing dynamic translations are omitted instead of fabricating 404 alternates;
- the sitemap includes canonical static and dynamic pages and excludes the
  redirect-only service roots;
- non-canonical environments are blocked by both page metadata and `robots.txt`;
- the project emits Organization, WebSite, Service, BlogPosting, Person,
  CreativeWork, and BreadcrumbList JSON-LD where appropriate;
- the locale layout owns the sole document root and main landmark;
- blog archives expose crawlable server-rendered links and use optimized images;
- GA4 page-view loading exists when `NEXT_PUBLIC_GA_MEASUREMENT_ID` is set;
- confirmed lead conversion events, consent management, Ads tags, and campaign
  attribution are not yet implemented.

Always verify the deployed site. Source review cannot prove that production
environment variables, CDN behavior, redirects, headers, DNS, or hosted accounts
are configured correctly.

## Production Crawl Contract

The application is publicly indexable only when both conditions are true:

```text
NODE_ENV=production
NEXT_PUBLIC_SITE_URL=https://feaon.com
```

`isPublicProduction()` in `lib/config/env.ts` enforces this exact contract.

When the contract is not satisfied:

- page metadata emits `noindex, nofollow`;
- `robots.txt` returns `Disallow: /`;
- the deployment is intentionally not crawlable.

This includes local development, preview deployments, staging domains, and a
production build with a missing or non-canonical site URL.

Do not weaken the fail-closed code to make a preview URL indexable. Correct the
deployment configuration or obtain approval for an architecture change.

Safe examples:

```bash
# Local or preview: noindex by design
NEXT_PUBLIC_SITE_URL=http://localhost:3000

# Canonical production
NEXT_PUBLIC_SITE_URL=https://feaon.com
```

Never commit real values from production environment files. `.env.example` may
contain only variable names and safe placeholders.

## SEO Text and Fallback Order

### Static content documents

`getStaticContentMetadata()` reads the full Supabase content document and uses:

```text
title:       seo_title -> document title -> page fallback title
description: seo_description -> page fallback description
```

The page fallback is usually existing hero copy. It protects rendering when an
optional SEO field is empty, but it is not a replacement for publishing useful
SEO fields in both locales.

### Dynamic blog posts and case studies

`buildDynamicArticleMetadata()` uses:

```text
title:       seo_title -> content title
description: seo_description -> content description/excerpt/summary
```

Dynamic records may also provide:

- image;
- published timestamp;
- updated timestamp;
- author.

The updated timestamp is preferred for sitemap `lastModified`; the published
timestamp is the fallback.

### Editorial expectations

For every published VI and EN translation:

- use a unique title that describes the page intent;
- use a specific description instead of a generic site-wide sentence;
- avoid identical SEO titles across unrelated pages;
- ensure the social image represents the page;
- keep the content title and SEO title semantically aligned;
- do not publish an alternate-language row unless its route and content are
  actually available.

## Adding a Static Localized Page

### 1. Select the correct route registry

Use the existing definitions in `lib/routes/routes.ts`:

- `STATIC_ROUTE_DEFS` for top-level static roots, including redirect-only roots;
- `CATEGORY_ROUTE_DEFS` for real category or marketing pages;
- `SERVICE_ROUTE_DEFS` for real service detail pages.

Define both localized paths. Vietnamese is the default locale and has no `/vi`
prefix. English is rendered below `/en`.

### 2. Understand the exact sitemap behavior

The registries do not currently expose identical sitemap controls:

- `STATIC_ROUTE_DEFS` includes a `sitemap` field, and
  `lib/seo/site.ts` propagates that field. Use `sitemap: false` for a
  redirect-only static root such as `/services` and `/dich-vu`.
- `CATEGORY_ROUTE_DEFS` does not currently expose a sitemap field.
  `lib/seo/site.ts` maps every category definition with `sitemap: true`.
- `SERVICE_ROUTE_DEFS` does not currently expose a sitemap field.
  `lib/seo/site.ts` maps every service definition with `sitemap: true`.

Therefore, do not add a redirect-only category or service definition and assume
that writing `sitemap: false` will work. The current types and mapping would not
honor that instruction.

If a future approved route requires a redirect-only entry outside
`STATIC_ROUTE_DEFS`, the implementation must also:

1. extend the relevant route definition type with an explicit sitemap policy;
2. propagate that policy in `getStaticMarketingRoutes()`;
3. update `getSitemapMarketingRoutes()` expectations;
4. add route-registry and sitemap tests;
5. verify the redirect URL is absent while its canonical destination remains.

A redirect must never appear as a canonical sitemap entry.

### 3. Publish Supabase content translations

Create or update the associated content document for `vi` and `en`, including:

- payload required by the page;
- `title` when used by the document model;
- `seo_title`;
- `seo_description`.

Do not restore repository JSON fallbacks. Managed content remains Supabase-owned.

### 4. Add route-level metadata

Use `getStaticContentMetadata()` in the page boundary:

```ts
import type { Metadata } from 'next';
import { getStaticContentMetadata } from '@/lib/seo/static-content-metadata';
import {
  type AppLocale,
  getStaticMarketingRoutePaths,
} from '@/lib/seo/site';

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;

  return getStaticContentMetadata({
    locale: locale as AppLocale,
    paths: getStaticMarketingRoutePaths('/about'),
    contentDocumentKey: 'about',
    getFallbacks: ({ payload }) => ({
      title: payload.page.hero.title,
      description: payload.page.hero.description,
      image: payload.page.hero.backgroundSrc,
    }),
  });
}
```

Replace the route ID, content-document key, and payload fallback paths with the
new page values.

The shared builder generates:

- self-referencing canonical URL;
- available VI/EN language alternates;
- Open Graph URL and locale;
- optional alternate Open Graph locale;
- Twitter summary-card metadata.

Do not put homepage canonical or route-specific Open Graph URLs in a shared
layout.

### 5. Add appropriate structured data

Use builders in `lib/seo/json-ld.ts` and render them through `JsonLd`:

```tsx
import { JsonLd } from '@/components/shared/json-ld';
import { buildServiceJsonLd } from '@/lib/seo/json-ld';

<JsonLd
  data={buildServiceJsonLd({
    name,
    description,
    url: canonicalUrl,
  })}
/>
```

Current schema choices:

- homepage: `Organization` and `WebSite`;
- service detail: `Service`;
- blog post: `BlogPosting`;
- author page: `Person`;
- case study: `CreativeWork`;
- hierarchical routes: `BreadcrumbList`.

Only emit facts that exist in the content model. Do not invent ratings, prices,
addresses, authors, dates, or organization properties for richer results.

### 6. Preserve document semantics

- Do not add `<main>` inside a route page.
- Use one intentional page-level H1.
- Use H2/H3 in logical order.
- Keep navigation links as ordinary anchors.
- Use `next/image` or the existing shared image component with dimensions or
  `fill` and a correct `sizes` value.

## Dynamic Blog and Case-Study SEO

Dynamic translations can use different slugs:

```text
VI: /blog/post/thiet-ke-web-chuyen-nghiep
EN: /en/blog/post/professional-web-design
```

Both translations must reference the same stable base content ID in Supabase.

The metadata flow is:

```text
Supabase translations
  -> server SEO records with contentId and locale
  -> buildLocalizedContentMap()
  -> active lookup by locale + slug
  -> sibling lookup by stable contentId
  -> canonical, hreflang, Open Graph, and sitemap URLs
```

Never resolve the sibling locale by reusing the active slug.

If only one published translation exists, metadata and sitemap must emit only
that locale. Do not fabricate an alternate URL.

Page boundaries should reuse `buildDynamicArticleMetadata()`:

```ts
return (
  buildDynamicArticleMetadata({
    locale: appLocale,
    slug: postSlug,
    records: [...viRecords.data, ...enRecords.data],
    getPath: getBlogPostRoutePath,
    siteName,
  }) ?? {}
);
```

For case studies, use `getCaseStudyRoutePath` and case-study SEO records.

When adding another dynamic content type, first define:

1. a stable base content ID shared by translations;
2. a server SEO record satisfying `DynamicSeoRecord`;
3. a locale-aware path helper;
4. metadata tests for different slugs and missing translations;
5. sitemap generation from the same translation map.

Do not create one translation map for metadata and a separate incompatible map
for the sitemap.

## Canonical and Hreflang Rules

Every indexable route must satisfy:

- canonical points to the currently rendered locale and pathname;
- canonical is absolute and uses the configured site origin;
- VI and EN alternates are reciprocal when both translations exist;
- each alternate uses its own localized pathname or slug;
- missing translations are omitted;
- redirect aliases are not canonical entries;
- Open Graph URL equals the canonical URL.

Use these helpers instead of manual string concatenation:

- `getLocalizedUrl()`;
- `getStaticMarketingRoutePaths()`;
- `getBlogCategoryRoutePaths()`;
- `getBlogPostRoutePath()`;
- `getCaseStudyRoutePath()`;
- `getAvailableAlternates()`.

Current URL model:

```text
Vietnamese homepage: https://feaon.com/
English homepage:    https://feaon.com/en
Vietnamese page:     https://feaon.com/<vi-path>
English page:        https://feaon.com/en/<en-path>
```

## Sitemap Rules

`app/sitemap.ts` combines route-registry output and dynamic Supabase SEO records.

### Static marketing entries

- `STATIC_ROUTE_DEFS` honors its explicit `sitemap` field.
- Category definitions are currently included by construction.
- Service definitions are currently included by construction.
- `/services` and `/dich-vu` are redirect-only static roots and are excluded.
- Service detail pages remain included with localized alternates.

### Blog collection entries

The sitemap also includes:

- `/blog/newest`;
- published blog categories;
- published author archives.

These collection entries are currently generated per locale and declare only the
active locale alternate. They are not paired by stable translation ID.

Do not claim reciprocal collection hreflang unless the data model and mapping
have been explicitly upgraded and tested.

### Dynamic detail entries

Blog posts and case studies:

- are grouped by stable content ID;
- use each translation's own slug;
- omit unavailable translations;
- use `updatedAt`, falling back to `publishedAt`, for `lastModified`.

### Entry requirements

Every sitemap entry must:

- resolve to a canonical 200 page;
- not be a permanent redirect alias;
- use the same localized path as page metadata;
- include only real published translations;
- use a reliable `lastModified` value when available.

Do not manually insert URLs that should be derived from the route registry or
dynamic SEO records.

## Robots and Noindex Behavior

`app/robots.ts` and locale-layout metadata both consume
`isPublicProduction()`.

| Environment | Page robots metadata | `robots.txt` |
| --- | --- | --- |
| Canonical production | `index, follow` | `Allow: /` plus sitemap and host |
| Local, preview, staging, or misconfigured production | `noindex, nofollow` | `Disallow: /` |

Robots exclusion alone does not replace page-level `noindex`. Preserve both
layers unless an approved architecture change replaces the policy.

## Structured-Data Safety

Use `serializeJsonLd()` through `components/shared/json-ld.tsx`. It escapes `<`
to reduce unsafe script-content risk.

Structured-data URLs must be canonical and localized. Breadcrumbs must follow
the user-visible hierarchy and use real URLs.

Update visible content and schema inputs together. Schema must not describe
content that the page does not display.

Future optional enhancements, only with verified data:

- Organization logo;
- official `sameAs` profiles;
- public contact point;
- verified address;
- a connected `WebPage` graph.

Do not invent these values.

## Blog Crawlability and Images

The interactive load-more UI is supplemented by server-rendered `<noscript>`
archive anchors so every published post remains reachable without a client-only
click path.

When changing blog listings:

- preserve ordinary crawlable anchors;
- do not replace the archive with JavaScript-only navigation;
- avoid indexable empty category or author pages;
- keep links locale-aware;
- consider real server pagination when the archive grows substantially.

Blog media should use `components/shared/blog-image.tsx` or `next/image` with
appropriate dimensions and `sizes`.

The project should eventually provide a default 1200x630 Open Graph image and a
validated page-specific social-image override. A default image is a fallback,
not a substitute for relevant page media.

## WordPress SEO Feature Parity

Feaon already produces most crawler-facing output normally supplied by WordPress
plus an SEO plugin. The main gaps are editor convenience, previews, and
operational monitoring.

| Capability | Feaon | Typical WordPress SEO plugin |
| --- | --- | --- |
| Per-page SEO title and description | Yes, Supabase-backed | Yes |
| Canonical URL | Yes, centralized | Yes |
| VI/EN hreflang | Yes for static and stable-ID dynamic details | Often needs multilingual integration |
| XML sitemap | Yes | Yes |
| Preview/staging noindex | Yes, fail-closed | Hosting/plugin dependent |
| Open Graph and Twitter metadata | Yes | Yes |
| Main structured-data types | Yes | Usually a broader graph |
| Per-page index/noindex control | Not exposed in CMS | Usually available |
| Canonical override | Not exposed in CMS | Usually available |
| Dedicated social-image override | Not standardized | Usually available |
| Redirect manager | No admin UI | Often available |
| 404 monitoring | No built-in dashboard | Available in some plugins |
| SEO preview/readability score | No | Common |
| Image/video/news sitemap | No | Available through add-ons |
| Search Console/Analytics dashboard | No | Often available through integrations |

Potential future CMS fields:

```text
seo_social_image
seo_indexable
canonical_override
sitemap_include
```

`seo_indexable`, `canonical_override`, and `sitemap_include` are high-risk
controls. Do not expose them as unrestricted editor fields. They require
validation, safe defaults, tests, preview behavior, and governance.

## Readiness Baseline

This baseline was reviewed on 2026-08-05 against `main` commit `12e7b901`.
Scores are directional maintenance aids, not guarantees.

| Area | Baseline | Status |
| --- | ---: | --- |
| Technical SEO configuration | 8.7/10 | Production-ready after live verification |
| Route metadata | 9/10 | Centralized and Supabase-backed |
| Canonical URLs | 9.5/10 | Self-canonical through route registry |
| International SEO | 9/10 | Strong for static and dynamic detail routes |
| Sitemap and robots | 9/10 | Dynamic and fail-closed outside production |
| Structured data | 8/10 | Main schema types implemented |
| Semantic HTML and crawlability | 8.5/10 | One main landmark and crawlable archives |
| Image and social SEO | 8/10 | Blog optimized; default/override social image can improve |
| CMS/editor controls | 6.5/10 | Core SEO fields exist; advanced controls do not |
| Search Console readiness | 9/10 | Ready after production verification |
| Ads landing-page readiness | 8/10 | Forms and service pages can receive traffic |
| Ads measurement readiness | 4/10 | Conversion, consent, and attribution remain |

Remember:

```text
Technical SEO ready
  != Search Console configured
  != Analytics verified
  != Ads conversion tracking ready
```

Update this table after a major routing, CMS, deployment, analytics, or SEO
architecture change.

## Google Search Console Setup

The repository is ready for Search Console after the canonical production deploy
passes live verification.

Prefer a Domain property verified through DNS because it covers the canonical
domain without adding a verification token to application source.

### Production prerequisites

Verify live:

```text
https://feaon.com/
https://feaon.com/robots.txt
https://feaon.com/sitemap.xml
```

Confirm:

- production satisfies the exact crawl contract;
- representative pages do not emit `noindex`;
- `robots.txt` allows crawling and references the production sitemap;
- the sitemap returns 200 and contains canonical URLs only;
- canonical, hreflang, Open Graph URL, and JSON-LD use the production origin;
- redirect aliases are absent;
- representative localized URLs return the expected 200 or redirect status.

### Setup sequence

1. Create a Search Console Domain property for `feaon.com`.
2. Add the DNS TXT record supplied by Google through the authoritative DNS
   provider.
3. Verify ownership.
4. Submit `https://feaon.com/sitemap.xml`.
5. Inspect:
   - `/` and `/en`;
   - one VI/EN static page pair;
   - one VI/EN service pair;
   - one VI/EN blog-post pair with different slugs;
   - one VI/EN case-study pair.
6. Confirm Google's selected canonical matches the application canonical.
7. Monitor indexing, sitemap processing, Core Web Vitals, enhancements, security
   issues, and manual actions.

DNS, Search Console ownership, and verification values are hosted operational
state. Do not commit them.

### Ongoing routine

After major releases:

- check sitemap processing;
- inspect changed routes;
- review excluded and not-indexed reasons;
- compare submitted and indexed URLs;
- check canonical selection and mobile/Core Web Vitals;
- review structured-data errors.

Monthly:

- review clicks, impressions, CTR, and average position by page and query;
- compare VI and EN separately;
- find high-impression, low-CTR pages for title/description review;
- investigate declining pages before rewriting or redirecting;
- inspect 404, soft-404, duplicate-canonical, and crawl anomalies.

Do not change canonical or hreflang rules solely to chase short-term metrics
without identifying the technical cause.

## Analytics and Google Ads Readiness

### Current implementation

`app/[locale]/layout.tsx` can load GA4 directly when
`NEXT_PUBLIC_GA_MEASUREMENT_ID` is configured.

At this baseline, the repository does not contain:

- a Google Tag Manager container integration;
- a Google Ads `AW-...` conversion tag;
- a confirmed form-success conversion event;
- Consent Mode or a consent-management platform integration;
- campaign attribution stored with leads;
- enhanced conversions;
- built-in phone, email, WhatsApp, or CTA conversion events.

Contact and consultation forms update their UI after a successful API response,
but that success branch does not currently emit an analytics or Ads event.

Do not treat a page view, button click, form-submit attempt, or client-side
validation pass as a confirmed lead.

### Choose one tag architecture

A future approved implementation should choose one primary architecture:

1. Google Tag Manager for GA4, Ads, consent, and future marketing tags; or
2. direct `gtag` integration maintained in application code.

Do not operate unmanaged duplicate tags for the same property because page views
and conversions can be counted twice.

The implementation Issue must define:

- account and container ownership;
- environment-variable names and safe placeholders;
- consent behavior;
- event names and payloads;
- test and debug procedure;
- rollout and rollback;
- the source of truth for Ads conversion reporting.

### Lead conversion event contract

Emit a lead event only after the backend confirms `result.ok`.

Recommended logical event:

```text
event: generate_lead
lead_type: contact | consultation
submission_id: stable non-PII submission identifier
locale: vi | en
```

A GTM data-layer shape may resemble:

```ts
window.dataLayer?.push({
  event: 'generate_lead',
  lead_type: 'contact',
  submission_id: identity.id,
  locale,
});
```

Requirements:

- fire only after confirmed backend success;
- do not include name, phone, email, free-text message, or raw PII;
- deduplicate retries and re-renders;
- distinguish contact and consultation leads;
- test both locales and success/error paths;
- document whether GA4 import or a direct Ads tag is Primary.

Do not mark the same logical lead as Primary through both GA4 import and a direct
Ads event unless the measurement design explicitly prevents double counting.

### Ads enablement sequence

Before scaling paid traffic:

1. implement and test consent behavior;
2. implement confirmed-success `generate_lead`;
3. configure the selected GA4/GTM or direct-tag architecture;
4. create the Ads conversion action;
5. choose one Primary reporting path per logical lead;
6. test with browser debug tools and platform diagnostics;
7. submit controlled test leads;
8. confirm one conversion per successful lead;
9. exclude internal or test traffic where appropriate;
10. verify final URLs, mobile forms, privacy content, and redirects;
11. begin with conservative budgets until lead quality is confirmed.

The site can receive paid traffic before every optional enhancement exists, but
conversion-based bidding should not be trusted until measurement is accurate,
consent-aware, deduplicated, and tied to real successful leads.

## Consent, Privacy, and Attribution

### Consent and privacy

Consent Mode does not replace a user-facing consent banner or consent-management
platform.

Before enabling optional Analytics, Ads, or remarketing behavior:

- review requirements for target markets;
- implement a clear consent interface where required;
- define default and updated consent states;
- prevent optional tags from bypassing consent;
- provide withdrawal or preference controls where required;
- update Supabase-managed privacy-policy content before rollout;
- document processors, retention, advertising use, and contact channels.

The privacy policy must describe the actual implementation, not planned future
features.

### Campaign attribution

To understand which campaigns create useful leads, a future approved
implementation may associate these fields with the server-side lead:

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

Requirements:

- sanitize and length-limit values;
- never trust attribution for authorization or business logic;
- define first-touch, last-touch, or another explicit attribution policy;
- include schema, retention, privacy, and deletion implications;
- preserve lead idempotency and retry behavior;
- do not put secrets or internal data in query parameters.

Enhanced conversions are optional follow-up work. Implement them only after the
basic conversion event, consent model, privacy disclosure, PII handling, and
deduplication are correct.

## Recommended Follow-up Roadmap

### P0: production SEO and Search Console

- merge and maintain this guide;
- verify the production crawl contract;
- inspect live metadata, robots, sitemap, and JSON-LD;
- configure the Search Console Domain property;
- submit the sitemap and inspect representative routes;
- add a default Open Graph image if live social previews are incomplete.

### P1: measurement before scaling Ads

- approve GTM versus direct-tag architecture;
- implement consent or CMP behavior;
- emit confirmed-success `generate_lead` events;
- configure GA4 and one Primary Ads conversion path;
- capture approved attribution fields with leads;
- update privacy content;
- test both lead forms end to end.

### P2: WordPress-like editor controls

- add validated social-image override support;
- consider controlled per-page indexability only with governance;
- add a redirect registry or manager and 404 monitoring;
- provide metadata and social-preview tooling;
- add duplicate-title and missing-field reporting.

### P3: long-term enhancements

- enrich Organization schema with verified data;
- consider a connected `WebPage` graph;
- introduce real server pagination as the blog grows;
- use sitemap indexes or specialized sitemaps only when scale requires;
- improve Core Web Vitals using real production data;
- consider WOFF2 fonts and reduce unnecessary client animation cost.

## Verification Workflow

Use the repository-supported toolchain:

```text
Node.js 24.x
npm >=11 <12
```

Run checks proportional to the change:

```bash
npm run lint
npm run typecheck
npm test
npm run build
npm run content:verify-supabase-only
npm run content:build:synthetic
git diff --check
git status --short
```

For documentation-only changes, path inspection and `git diff --check` are
normally sufficient. Record skipped executable checks in the PR.

For SEO behavior changes, inspect rendered HTML for:

```text
/
/en
/gioi-thieu
/en/about
/blog
/en/blog
one blog category
one author page
one VI/EN blog-post pair
one VI/EN case-study pair
one VI/EN service pair
/chinh-sach-bao-mat
/en/privacy
/sitemap.xml
/robots.txt
```

Confirm:

- `<html lang>` matches the locale;
- one `<main>` and one intended H1;
- unique title and description;
- self canonical;
- expected available hreflang values;
- Open Graph URL, locale, and image;
- expected robots metadata;
- route-appropriate JSON-LD;
- canonical sitemap entries and excluded redirects.

For future tracking changes, also confirm:

- tags respect consent state;
- page views are not double-counted;
- failed forms do not emit lead events;
- one successful form emits one lead event;
- retries do not duplicate conversions;
- no raw PII appears in analytics payloads;
- production and preview use intended tag behavior.

## Tests to Update

SEO behavior changes should add focused tests for:

- VI/EN route pairs with different paths;
- dynamic VI/EN items with different slugs;
- missing translations;
- SEO fields present and absent;
- redirect exclusion from sitemap;
- category/service sitemap mapping when registry behavior changes;
- production and non-production crawl modes;
- structured-data output.

Future tracking changes should test:

- event emission only after confirmed success;
- no event on validation, network, or backend error;
- retry deduplication;
- contact versus consultation properties;
- consent-granted and consent-denied paths;
- absence of raw PII;
- disabled-tag and environment parsing behavior.

## Production SEO and Ads Launch Checklist

Before Search Console submission:

- [ ] Production satisfies the exact crawl contract.
- [ ] Representative pages return expected statuses.
- [ ] No production page accidentally emits `noindex`.
- [ ] `robots.txt` allows crawling and references the sitemap.
- [ ] `sitemap.xml` returns 200 and excludes redirect aliases.
- [ ] Canonical and hreflang URLs resolve.
- [ ] JSON-LD uses canonical URLs and visible facts.
- [ ] The Domain property is DNS-verified.
- [ ] The sitemap is submitted.
- [ ] Representative URLs are inspected.

Before scaling Google Ads:

- [ ] One tag architecture is approved.
- [ ] Consent behavior is implemented and tested.
- [ ] Privacy content matches enabled tracking.
- [ ] Contact success emits one deduplicated lead event.
- [ ] Consultation success emits one deduplicated lead event.
- [ ] No raw PII is sent in analytics events.
- [ ] One Primary conversion source is defined per logical lead.
- [ ] Attribution is captured according to the approved policy.
- [ ] Test leads appear in the lead system and reporting tools.
- [ ] Mobile landing pages and forms are tested.
- [ ] Campaign final URLs avoid unnecessary redirects.

## Common Failure Modes

| Symptom | Likely cause | Correct fix |
| --- | --- | --- |
| Child page canonical points to `/` or `/en` | Route-specific canonical was added to a shared layout | Move canonical generation to the page metadata builder |
| English route renders Vietnamese `lang` | The locale document root was bypassed | Keep the sole locale-aware `<html>` in the locale layout |
| Dynamic hreflang returns 404 | Active slug was reused for the sibling locale | Match by stable content ID and use each localized slug |
| Preview is indexable | Crawl policy was bypassed | Restore `isPublicProduction()` in metadata and robots |
| Production is `noindex` | Canonical site URL is missing or different | Correct deployment configuration |
| Redirect static root appears in sitemap | `STATIC_ROUTE_DEFS.sitemap` is wrong | Set the static root to `sitemap: false` and test |
| Redirect category/service appears in sitemap | Registry mapping always includes that definition | Extend the registry policy and `lib/seo/site.ts`; do not add a no-op field |
| CMS SEO fields do not appear | Page reads only message payload | Use the full cached document and shared metadata helper |
| Duplicate `<main>` landmarks | Route page adds another `<main>` | Use `div`, `section`, or fragment |
| Old blog posts are unreachable | Client-only navigation removed archive anchors | Restore server links or approved pagination |
| JSON-LD disagrees with the page | Schema values were hard-coded | Build from the same localized content and canonical URL |
| GA4 shows sessions but no leads | No success conversion event exists | Emit a deduplicated event after backend success |
| Ads counts more conversions than leads | Multiple Primary paths or retry duplication | Choose one Primary path and deduplicate |
| A form click counts as a lead | Event fires on click or submit attempt | Move it to the `result.ok` branch |
| Tags fire before consent | Consent defaults or triggers are wrong | Correct CMP and Consent Mode behavior |
| Campaign source is unknown | Attribution identifiers are not retained | Capture approved attribution fields |
| Privacy policy disagrees with tracking | Policy was not updated | Update managed policy content before rollout |

## Change Policy

SEO configuration and acquisition measurement are production behavior, not
decorative copy.

Changes to the canonical domain, locale URL model, crawl policy, route registry,
content schema, sitemap rules, structured-data strategy, analytics architecture,
consent behavior, attribution model, or Ads conversion model require:

1. an explicit GitHub Issue;
2. defined scope and out-of-scope boundaries;
3. implementation and tests;
4. production impact and rollback;
5. independent review;
6. human approval for hosted mutations.

When an approved decision changes this architecture, update this guide in the
same PR so future contributors do not follow superseded behavior.
