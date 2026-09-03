---
name: sitemap-general
description: "Use when creating or configuring a sitemap for any website (any domain, any stack). Covers XML sitemap generation, robots.txt linkage, multilingual hreflang, image/video extensions, lastModified strategy, pagination/canonical handling, and Search Console submission. Trigger on 'create sitemap', 'config sitemap', 'sitemap cho web mới'."
---

# Sitemap — General Skill (Framework-Agnostic)

Reusable for **any domain / any industry**. No portfolio-specific assumptions. Copy this file to the target repo and follow the checklist.

## 1. What is a sitemap?

An XML file at `https://example.com/sitemap.xml` that lists canonical URLs you want search engines to crawl. It is a **hint, not a guarantee** — Google still respects `robots.txt`, `noindex`, canonical and crawl budget.

Types you may need:
- **URL sitemap** — standard `<urlset><url><loc>...` (this skill's default)
- **Sitemap index** — `sitemap-index.xml` → points to `sitemap-posts.xml`, `sitemap-pages.xml`... Required only when >50k URLs or >50MB uncompressed per file.
- **Image / Video / News extensions** — optional `<image:image>`, `<video:video>` inside each `<url>`.

This skill focuses on the URL sitemap; extend to image/video only if the site is image/video-heavy.

## 2. Decide the URL set

Include **only**:
- Canonical, indexable (`200`, `index` allowed), self-referencing canonical URLs.
- Preferred locale/version (e.g. `https://example.com/blog/foo`, not both `https://example.com/blog/foo/` with trailing slash duplicate).

Exclude:
- `noindex`, `404/301/302` targets, pagination `?page=2` (usually), admin/api/auth, non-canonical duplicates, soft-404s.
- If a section is empty (e.g. a tag with 0 published posts), omit its URL — do not list empty archives.

## 3. Minimal valid XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2026-09-03T00:00:00.000Z</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
    <xhtml:link rel="alternate" hreflang="en" href="https://example.com/"/>
    <xhtml:link rel="alternate" hreflang="vi" href="https://example.com/vi"/>
    <xhtml:link rel="alternate" hreflang="x-default" href="https://example.com/"/>
  </url>
</urlset>
```

If you add an XSL stylesheet for human-readable rendering (WordPress Yoast does), prepend:

```xml
<?xml-stylesheet type="text/xsl" href="/sitemap.xsl"?>
```

It is **cosmetic only** — Google ignores it.

## 4. Generate in Next.js App Router (recommended)

Create one file — no `public/sitemap.xml` needed:

```ts
// src/app/sitemap.ts
import type { MetadataRoute } from "next";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = "https://example.com"; // replace per env; never hardcode portfolio domain

  // Fetch canonical data from DB/CMS (filter published + not soft-deleted)
  const posts = await fetchPublishedPosts(); // [{ slug, updatedAt, publishedAt }]
  const categories = await fetchCategories(); // [{ slug, updatedAt }]
  const tags = await fetchTags(); // [{ slug, updatedAt }]

  // Stable lastmod for aggregated routes = freshest child, not `new Date()` per request
  const latest = posts.reduce<Date | null>((m, p) => {
    const d = new Date(p.updatedAt || p.publishedAt);
    return !m || d > m ? d : m;
  }, null) ?? new Date();

  return [
    { url: `${base}/`, lastModified: latest, changeFrequency: "monthly", priority: 1 },
    { url: `${base}/blog`, lastModified: latest, changeFrequency: "weekly", priority: 0.8 },
    ...posts.map((p) => ({
      url: `${base}/blog/${p.slug}`,
      lastModified: new Date(p.updatedAt || p.publishedAt),
      changeFrequency: "monthly" as const,
      priority: 0.7,
      alternates: {
        languages: {
          en: `${base}/blog/${p.slug}`,
          vi: `${base}/vi/blog/${p.slug}`,
          "x-default": `${base}/blog/${p.slug}`,
        },
      },
    })),
    ...categories.map((c) => ({
      url: `${base}/blog/category/${c.slug}`,
      lastModified: c.updatedAt ? new Date(c.updatedAt) : latest,
      changeFrequency: "monthly" as const,
      priority: 0.6,
    })),
    ...tags.map((t) => ({
      url: `${base}/blog/tag/${t.slug}`,
      lastModified: t.updatedAt ? new Date(t.updatedAt) : latest,
      changeFrequency: "monthly" as const,
      priority: 0.5,
    })),
  ];
}
```

Notes:
- Return type `MetadataRoute.Sitemap` auto-serializes to correct XML.
- For i18n, generate one entry **per locale** or use `alternates.languages` as above. Either is valid; `alternates` is preferred for `hreflang`.
- `revalidate` / `expire` are optional: `export const revalidate = 86400` (1 day) if you want ISR; otherwise sitemap is dynamic and benefits from data-cache tags.

Vanilla / other stacks: expose `GET /sitemap.xml` that returns the same XML string with header `Content-Type: application/xml; charset=utf-8`.

## 5. Per-field best practices

| Field | Rule |
|---|---|
| `loc` | Absolute URL, canonical, `https`, no trailing-slash duplicates. Must match `rel=canonical` on the page. |
| `lastmod` | W3C datetime (`YYYY-MM-DD` or full ISO). **Stable**: derive from DB `updated_at` / `published_at` (e.g. `MAX(posts.updated_at)` per category/tag). Never `new Date()` on every request — it makes `lastmod` meaningless and forces re-crawl. Fallback to latest post date if child has no date. |
| `changefreq` | Hint only (`always|hourly|daily|weekly|monthly|yearly|never`). Use `weekly` for listing pages, `monthly` for archives, `never` rarely. Google largely ignores it — `lastmod` matters more. |
| `priority` | `0.0–1.0`, relative within your site. `1.0` = homepage, `0.8` = section index, `0.7` = detail, `0.6` = category, `0.5` = tag. Do not set all to `1.0`. |
| `hreflang` | When multilingual, every URL must list **all** locales + `x-default` (usually points to default locale). See example above. The URL itself is the canonical for its locale; `x-default` is not a separate entry. |
| `images` | Add `<image:image><image:loc>...</image:loc></image:image>` only if image SEO matters; otherwise omit. |

## 6. Pagination & canonical

- **Do not** list `/blog/page/2`, `/blog/page/3` in the sitemap. Only list the canonical section URL (`/blog`). Let pagination be discovered via `<link rel="next/prev">` or internal links; the canonical for `page=1` is `/blog`, and `page>1` is `noindex` or canonical to itself but not in sitemap.
- The detail page for `page=N` should `308/301` redirect `page=1 → /blog` to avoid duplication.

## 7. robots.txt

Always reference the sitemap:

```ts
// src/app/robots.ts (Next) or public/robots.txt
User-agent: *
Allow: /
Disallow: /admin
Disallow: /api/
Sitemap: https://example.com/sitemap.xml
```

Adjust `Disallow` per site (admin, api, preview). Set `noindex` at the HTTP/meta level for admin — `robots.txt` disallow alone does not prevent indexing if linked externally.

Next.js: `src/app/robots.ts` returning `MetadataRoute.Robots` is equivalent.

## 8. Caching & invalidation

- Cache the sitemap (`1d` is typical). In Next, use data-cache tags:
  ```ts
  // repository.ts
  export const getPublishedPostIndex = unstable_cache(fn, ["sitemap-posts"], { tags: ["content"], revalidate: 86400 });
  // admin mutation
  updateTag("content"); // or revalidateTag("content")
  ```
  So any publish/edit/unpublish immediately invalidates the sitemap on next request.
- Safety net `revalidate` (e.g. `86400`) catches missed invalidations.

## 9. Split when large

If `urls > 40k` (leave headroom before 50k) or `bytes > 45MB`, switch to sitemap index:

```xml
<!-- /sitemap.xml becomes index -->
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <sitemap><loc>https://example.com/sitemap-posts.xml</loc><lastmod>...</lastmod></sitemap>
  <sitemap><loc>https://example.com/sitemap-categories.xml</loc></sitemap>
</sitemapindex>
```

Each child is a standard `<urlset>`. Reference the index in `robots.txt`.

## 10. Validate before submitting

Local checks:
```bash
curl -s https://example.com/sitemap.xml | head -n 20
curl -s https://example.com/robots.txt
npx next build # ensures /sitemap.xml route builds
```

Online validators:
- https://www.xml-sitemaps.com/validate-xml-sitemap.html
- Google Search Console → Sitemaps → enter `sitemap.xml` → must show `Success` and `Discovered URLs` count.

Common failures: `loc` not absolute, `loc` returns non-200, `lastmod` badly formatted, URLs blocked by `robots.txt`, sitemap listed `noindex` URLs.

## 11. Submit to search engines

- **Google Search Console:** `https://search.google.com/search-console` → pick property (`Domain` or `URL prefix` for `https://example.com`) → Left menu **Sitemaps** → **Add a new sitemap** → type `sitemap.xml` → Submit. No need to submit per-child when using index — submitting the index is enough.
- **Bing Webmaster Tools:** same flow (Sitemaps → Submit).
- Verify `https://example.com/robots.txt` contains `Sitemap:` — Bing and others auto-discover.

After submit, monitor **Coverage / Pages** for `Submitted and indexed` vs `Discovered - currently not indexed` — a large gap means crawl budget or quality issue, not sitemap syntax.

## 12. Checklist (copy for each new site)

- [ ] `loc` are absolute, https, canonical, 200, indexable; no admin/api/pagination/empty archives
- [ ] `lastmod` derived from DB (`updated_at` / `MAX(updated_at)` per aggregate), not `now()`; W3C ISO format
- [ ] `priority`/`changefreq` set relatively (1.0 → 0.5), not all 1.0
- [ ] `hreflang` (if multilingual) lists every locale + `x-default` on **each** URL
- [ ] `robots.txt` has `Sitemap: https://example.com/sitemap.xml` and correct `Disallow`
- [ ] Admin/API routes `noindex` (meta/headers), not relying solely on `robots.txt`
- [ ] Sitemap served as `Content-Type: application/xml`, cached (1d) and invalidated on content mutation
- [ ] Split to index if >40k URLs / >45MB
- [ ] Validated locally (`curl`, `next build`) and via online validator
- [ ] Submitted to GSC + Bing, and `Discovered URLs` matches expectation

## 13. Minimal template to copy

Replace `https://example.com` and the data fetchers; delete sections you don't need (e.g. tags).

```ts
// src/app/sitemap.ts — copy-paste starter
import type { MetadataRoute } from "next";
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? "https://example.com";
  const posts = await fetchPublishedPosts();
  const latest = posts.reduce<Date | null>((m, p) => {
    const d = new Date(p.updatedAt || p.publishedAt);
    return !m || d > m ? d : m;
  }, null) ?? new Date();
  return [
    { url: `${base}/`, lastModified: latest, changeFrequency: "monthly" as const, priority: 1 },
    ...posts.map((p) => ({
      url: `${base}/blog/${p.slug}`,
      lastModified: new Date(p.updatedAt || p.publishedAt),
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
  ];
}
```

```ts
// src/app/robots.ts — starter
import type { MetadataRoute } from "next";
export default function robots(): MetadataRoute.Robots {
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? "https://example.com";
  return { rules: [{ userAgent: "*", allow: "/", disallow: ["/admin", "/api/"] }], sitemap: `${base}/sitemap.xml` };
}
```

Keep `base` in one config file / env var; never hardcode a previous client's domain.
