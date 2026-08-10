# Hướng Dẫn Sử Dụng Supabase Trong Next.js Cùng Coding Agent (Codex + Command Code)

> Tài liệu thiết kế lịch sử: các ví dụ seed JSON trong repo có trước khi dự án
> chuyển hoàn toàn sang Supabase. Content production hiện thuộc cloud và pipeline
> import local cũ đã được gỡ bỏ.

Tài liệu này tổng hợp patterns, workflow, và bài học từ dự án Feaon-ldp-v2 — một Next.js app sử dụng Supabase cho content management và lead processing, được phát triển cùng Codex (planner/reviewer) và Command Code (implementer).

---

## 1. Tổng Quan Kiến Trúc

### 1.1. Vai Trò Của Supabase

Dự án dùng Supabase cho hai mục đích chính:

- **Content Platform**: Lưu trữ và phân phối nội dung đa ngôn ngữ (`vi`/`en`) — blog, case studies, static pages. Thay thế dần nội dung local JSON/Markdown.
- **Lead Management**: Lưu trữ lead submissions từ form liên hệ, xử lý retry delivery qua PostgreSQL function.

### 1.2. Mô Hình Dual-Source

Codebase được thiết kế để chạy với hoặc không có Supabase, thông qua biến môi trường `CONTENT_SOURCE_MODE`:

| Mode       | Hành vi                                       |
| ---------- | --------------------------------------------- |
| `local`    | Dùng JSON messages local, không gọi Supabase  |
| `supabase` | Chỉ dùng Supabase, crash nếu không có dữ liệu |
| `dual`     | Thử Supabase trước, fallback về local nếu lỗi |

**Tại sao cần dual-source**: Khi phát triển cùng coding agent, việc có fallback local giúp agent có thể test UI mà không cần Supabase running. Khi Supabase sẵn sàng, chuyển dần từng domain qua `supabase` mode.

### 1.3. Cấu Trúc Thư Mục

```
lib/supabase/
  client.ts           # Client factory: public + admin
  database.types.ts   # TypeScript types từ schema
  index.ts            # Barrel export

lib/data/
  content-repository.ts   # Core data retrieval (local + Supabase)
  content-cache.ts        # Next.js cache layer
  content-adapters.ts     # Local → Supabase data transformation

lib/api/
  lead-submission.ts      # Lead processing + retry logic

supabase/migrations/
  YYYYMMDDHHMMSS_content_platform_foundation.sql  # Schema + RLS

scripts/
  content-seed.ts     # Seed data từ local JSON → Supabase

app/api/
  contact/route.ts        # Contact form endpoint
  consultation/route.ts   # Consultation form endpoint
  revalidate-content/route.ts  # Webhook cache revalidation
  internal/retry-leads/route.ts  # Cron lead retry
```

---

## 2. Client Setup — Hai Loại Client

### 2.1. Public Client (Anon Key)

Dùng cho mọi thao tác đọc dữ liệu public từ client hoặc server component.

```ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

function createPublicSupabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return null; // Graceful degradation

  return createClient<Database>(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
}
```

**Key decisions**:

- **Stateless auth**: Không persist session, không auto-refresh — vì dự án không dùng Supabase Auth.
- **Return null nếu thiếu env**: Cho phép app chạy mà không cần Supabase (local mode).
- **Type-safe**: Generic `<Database>` từ `database.types.ts` để có full type checking.

### 2.2. Admin Client (Service Role)

Dùng server-only cho các thao tác ghi: insert lead, seed content, retry leads.

```ts
function createAdminSupabaseClient() {
  if (typeof window !== 'undefined') {
    throw new Error('Admin client cannot be used in the browser');
  }

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SECRET_KEY;
  if (!url || !key) return null;

  return createClient<Database>(url, key, {
    auth: { persistSession: false },
  });
}
```

**Key decisions**:

- **Browser guard**: `typeof window !== 'undefined'` check — crash sớm nếu vô tình import vào client component.
- **Service role key**: Bỏ qua RLS, có quyền đọc/ghi toàn bộ database.

---

## 3. Database Schema Design

### 3.1. Translation Pattern

Thay vì nhúng tất cả ngôn ngữ vào một bảng, tách riêng entity gốc và bản dịch:

```
blog_posts (entity gốc)
  ├── id: uuid PK
  ├── author_id: FK → blog_authors
  ├── category_id: FK → blog_categories
  ├── published_at: timestamptz
  ├── sort_order: int
  └── status: 'draft' | 'published' | 'archived'

blog_post_translations (bản dịch)
  ├── post_id: FK → blog_posts ON DELETE CASCADE
  ├── locale: 'vi' | 'en'
  ├── slug: text
  ├── title: text
  ├── excerpt: text
  └── body: jsonb   ← payload động
```

**Tại sao pattern này**:

- Entity gốc chứa metadata không phụ thuộc ngôn ngữ (sort_order, status, published_at).
- Translations chứa nội dung thực tế, dễ mở rộng thêm locale mới.
- FK cascade delete: xóa blog post → tự động xóa tất cả translations.
- `body: jsonb` cho phép cấu trúc động (intro, sections, call-to-action...).

### 3.2. Composite Unique Constraints

```sql
UNIQUE (post_id, locale)       -- mỗi locale chỉ có 1 bản dịch
UNIQUE (locale, slug)          -- slug phải unique trong cùng locale
```

### 3.3. Conditional Partial Indexes

Chỉ index bản ghi published để tối ưu hiệu năng:

```sql
CREATE INDEX idx_blog_posts_published ON blog_posts (published_at DESC)
  WHERE status = 'published';
```

---

## 4. Row Level Security (RLS)

### 4.1. Public Read Policy

Tất cả content tables đều có policy cho phép anon/authenticated SELECT, nhưng chỉ thấy bản ghi đã publish:

```sql
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY blog_posts_public_read ON blog_posts
  FOR SELECT TO anon, authenticated
  USING (
    status = 'published'
    AND (published_at IS NULL OR published_at <= now())
  );
```

**Logic**: "published_at IS NULL" cho phép bản ghi chưa set ngày publish vẫn hiển thị. "published_at <= now()" hỗ trợ scheduled publishing.

### 4.2. Lead Tables — No Public Access

```sql
-- KHÔNG có policy cho anon trên lead_submissions
-- Chỉ service_role mới đọc/ghi được
```

Lead data không bao giờ expose ra public. Chỉ admin client (service_role) mới truy cập được.

### 4.3. SECURITY DEFINER Function

```sql
CREATE FUNCTION private.claim_lead_notifications(batch_size int)
RETURNS SETOF lead_submissions
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT * FROM lead_submissions
  WHERE notification_status = 'pending'
    AND (next_attempt_at IS NULL OR next_attempt_at <= now())
  ORDER BY created_at
  LIMIT batch_size
  FOR UPDATE SKIP LOCKED;
$$;

REVOKE ALL ON FUNCTION private.claim_lead_notifications FROM PUBLIC;
```

**Pattern**: Hàm chạy với quyền của owner (service_role), cho phép SELECT FOR UPDATE mà không cần policy cho anon. Dùng `SKIP LOCKED` để nhiều worker retry song song không conflict.

---

## 5. Data Retrieval Patterns

### 5.1. Generic Fallback Orchestrator

Pattern core của dự án — một hàm generic quyết định nguồn dữ liệu:

```ts
async function readContent<T>(
  domain: ContentDomain,
  localReader: () => T | Promise<T>,
  remoteReader: () => T | null | Promise<T | null>
): Promise<ContentReadResult<T>> {
  const mode = readContentSourceMode();
  const domains = readCsvEnv('SUPABASE_CONTENT_DOMAINS');

  // Local mode hoặc domain không trong whitelist
  if (mode === 'local' || !domains.includes(domain)) {
    return { source: 'local', data: await localReader(), ok: true };
  }

  // Supabase mode
  try {
    const data = await remoteReader();
    if (data !== null) {
      return { source: 'supabase', data, ok: true };
    }
    // null = không có dữ liệu trong Supabase
    if (mode === 'dual') {
      console.warn(`[${domain}] Supabase returned null, falling back to local`);
      return { source: 'local', data: await localReader(), ok: true };
    }
    throw new Error(`[${domain}] No data in Supabase (mode: supabase)`);
  } catch (err) {
    if (mode === 'dual') {
      console.warn(`[${domain}] Supabase error, falling back to local:`, err);
      return { source: 'local', data: await localReader(), ok: true };
    }
    throw err;
  }
}
```

### 5.2. Parallel Supabase Queries

Khi fetch content phức tạp (blog: authors, categories, posts, translations), gọi tất cả query song song:

```ts
async function getSupabaseBlogSnapshot(locale: string) {
  const client = createPublicSupabaseClient();
  if (!client) return null;

  const [
    authors,
    authorTranslations,
    categories,
    categoryTranslations,
    posts,
    postTranslations,
  ] = await Promise.all([
    client.from('blog_authors').select('*').order('sort_order'),
    client.from('blog_author_translations').select('*').eq('locale', locale),
    client.from('blog_categories').select('*').order('sort_order'),
    client.from('blog_category_translations').select('*').eq('locale', locale),
    client.from('blog_posts').select('*').order('sort_order'),
    client.from('blog_post_translations').select('*').eq('locale', locale),
  ]);

  // Join thủ công bằng Map
  // authorTranslations → Map<author_id, translation>
  // ...
}
```

**Tại sao join thủ công thay vì Supabase joins**: Supabase joins với RLS có thể phức tạp và khó debug. Join trong application code dễ kiểm soát hơn, đặc biệt khi làm việc cùng coding agent.

### 5.3. `.maybeSingle()` cho Tra Cứu Đơn Lẻ

```ts
const { data: doc } = await client
  .from('content_documents')
  .select('id, document_key')
  .eq('document_key', key)
  .maybeSingle(); // Trả về null thay vì error nếu không tìm thấy
```

Dùng `.maybeSingle()` thay vì `.single()` khi không chắc chắn bản ghi tồn tại.

---

## 6. Next.js Cache Layer

### 6.1. unstable_cache Wrapper

```ts
import { unstable_cache } from 'next/cache';

export const getCachedBlogContent = (locale: string) =>
  unstable_cache(
    async () => getBlogContentSnapshot(locale),
    [`blog-content-${locale}`],
    {
      revalidate: 300, // 5 phút
      tags: ['content:blog', `content:blog:${locale}`],
    }
  )();
```

### 6.2. Webhook Revalidation

```ts
// app/api/revalidate-content/route.ts
export async function POST(request: Request) {
  const body = await request.json();
  const token = request.headers.get('x-revalidate-token');

  if (
    !token ||
    !timingSafeEqual(token, process.env.CONTENT_REVALIDATE_SECRET!)
  ) {
    return new Response('Unauthorized', { status: 401 });
  }

  const tags = body.tags ?? [
    'content:blog',
    'content:case-studies',
    'content:pages',
  ];
  for (const tag of tags) {
    revalidateTag(tag);
  }

  return Response.json({ revalidated: tags });
}
```

Pattern: Khi content thay đổi trong Supabase (manual edit hoặc seed), gọi webhook này để xóa Next.js cache.

---

## 7. Lead Submission Flow

### 7.1. Full Flow

```
User gửi form
  → Validate input (Zod schema)
  → Verify Turnstile (chống spam)
  → persistLead()       ← INSERT vào lead_submissions (admin client)
  → deliverLead()       ← Gửi email qua Resend API
  → recordDelivery()    ← UPDATE lead status + INSERT delivery attempt
```

### 7.2. Retry Queue với SELECT FOR UPDATE SKIP LOCKED

```ts
async function retryPendingLeads(batchSize: number) {
  const client = createAdminSupabaseClient();
  if (!client) return;

  // Gọi SECURITY DEFINER function claim batch lead
  const { data: leads } = await client.rpc('claim_lead_notifications', {
    batch_size: batchSize,
  });

  for (const lead of leads) {
    try {
      await deliverLead(lead);
      await recordSuccess(lead.id);
    } catch (err) {
      await recordFailure(
        lead.id,
        err,
        nextRetryDelay(lead.notification_attempts)
      );
    }
  }
}
```

**Retry strategy**: Exponential backoff — 1min, 5min, 15min, 1h, 6h, 24h.

### 7.3. Cron Trigger

```ts
// app/api/internal/retry-leads/route.ts
export async function POST(request: Request) {
  const token = request.headers.get('authorization')?.replace('Bearer ', '');
  if (!token || !timingSafeEqual(token, process.env.LEAD_RETRY_SECRET!)) {
    return new Response('Unauthorized', { status: 401 });
  }

  const result = await retryPendingLeads(50);
  return Response.json(result);
}
```

Trigger qua Supabase Cron hoặc external cron service gọi endpoint này.

---

## 8. Content Seeding

### 8.1. Deterministic UUID

```ts
function stableUuid(namespace: string, ...parts: string[]): string {
  const hash = createHash('sha256')
    .update(`${namespace}:${parts.join(':')}`)
    .digest();
  // Chuyển 16 bytes đầu thành UUID v5-style
  // Đảm bảo cùng input → cùng UUID mỗi lần seed
}
```

**Tại sao deterministic**: Cho phép chạy seed nhiều lần mà không tạo duplicate. Upsert dựa trên composite unique keys.

### 8.2. Seed Script Flow

```ts
// scripts/content-seed.ts
// 3 chế độ:
// --check  : Validate snapshot không rỗng
// --export : Xuất ra .content-seed/content-seed.v1.json
// --apply  : Seed vào Supabase (yêu cầu CONFIRM_REMOTE_SUPABASE_SEED=content-seed-v1)

async function applySnapshot(snapshot: ContentSeedSnapshot) {
  const client = createAdminSupabaseClient();

  // Upsert theo thứ tự: entities trước, translations sau
  await client
    .from('content_documents')
    .upsert(snapshot.documents, { onConflict: 'document_key' });
  await client
    .from('content_document_translations')
    .upsert(snapshot.documentTranslations, {
      onConflict: 'document_id, locale',
    });
  // ... tương tự cho blog authors, categories, posts, case studies
}
```

**Safety**: Yêu cầu env `CONFIRM_REMOTE_SUPABASE_SEED` match với version để tránh seed nhầm environment.

---

## 9. Workflow Với Coding Agent

### 9.1. Phân Chia Vai Trò

| Vai trò               | Codex                   | Command Code     |
| --------------------- | ----------------------- | ---------------- |
| Thiết kế schema       | ✅ Lên kế hoạch, review |                  |
| Viết migration SQL    | ✅ Review               | ✅ Implement     |
| Viết TypeScript types | ✅ Review               | ✅ Implement     |
| Viết client factory   | ✅ Review               | ✅ Implement     |
| Viết RLS policies     | ✅ Lên kế hoạch bảo mật | ✅ Implement     |
| Viết data repository  | ✅ Review pattern       | ✅ Implement     |
| Viết API routes       | ✅ Review               | ✅ Implement     |
| Viết seed scripts     | ✅ Review               | ✅ Implement     |
| Chạy migration        |                         | ✅ (cần confirm) |
| Chạy seed             |                         | ✅ (cần confirm) |
| Test end-to-end       | ✅ Verify               |                  |

### 9.2. Implementation Brief Mẫu Cho Command Code

Khi Codex giao task cho Command Code, brief nên có cấu trúc:

```
Task: Thêm bảng "testimonials" với translations

Files được phép:
- supabase/migrations/ (tạo migration mới)
- lib/supabase/database.types.ts (thêm types)
- lib/data/content-repository.ts (thêm reader)
- lib/data/content-adapters.ts (thêm adapter)
- scripts/content-seed.ts (thêm seed data)

Files không được đụng:
- lib/supabase/client.ts
- lib/data/content-cache.ts
- Các API routes hiện có

Acceptance criteria:
1. Migration có RLS policy SELECT cho anon/authenticated, chỉ published records
2. database.types.ts có Tables<'testimonials'> và Tables<'testimonial_translations'>
3. readContent() hỗ trợ domain 'testimonials'
4. Seed script seed được testimonials mẫu

Verification:
- pnpm typecheck
- pnpm lint
- Review migration SQL thủ công
```

### 9.3. Best Practices Khi Làm Việc Với Agent

1. **Luôn chạy typecheck sau khi sửa `database.types.ts`** — TypeScript là safety net chính.
2. **Không sửa migration đã deploy** — tạo migration mới thay vì sửa migration cũ.
3. **Test dual-source mode** — đảm bảo app vẫn chạy khi Supabase unavailable.
4. **Review RLS policies thủ công** — agent có thể viết policy quá rộng hoặc quá hẹp.
5. **Dùng `.maybeSingle()` thay vì `.single()`** — tránh crash khi không tìm thấy bản ghi.
6. **Không expose service_role key ra client** — admin client có browser guard.
7. **Dùng timing-safe comparison cho webhook auth** — tránh timing attack.

---

## 10. Environment Variables

```bash
# .env.local (không commit)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=eyJhbG...      # anon key
SUPABASE_SECRET_KEY=eyJhbG...                        # service_role (server only)

CONTENT_SOURCE_MODE=dual                             # local | dual | supabase
SUPABASE_CONTENT_DOMAINS=blog,case-studies,pages     # domains dùng Supabase

CONTENT_REVALIDATE_SECRET=random-string               # webhook auth
LEAD_RETRY_SECRET=random-string                       # cron auth
```

---

## 11. Các Pattern Nên Tránh

| ❌ Tránh                                   | ✅ Nên làm                                              |
| ------------------------------------------ | ------------------------------------------------------- |
| Gọi Supabase trực tiếp từ component        | Qua data layer (`content-repository` + `content-cache`) |
| Hardcode locale trong query                | Nhận locale từ params                                   |
| Dùng `.single()` khi không chắc có dữ liệu | Dùng `.maybeSingle()`                                   |
| Import admin client vào client component   | Browser guard + server-only pattern                     |
| Sửa migration đã deploy                    | Tạo migration mới                                       |
| Bỏ qua RLS "vì đang phát triển"            | Bật RLS ngay từ migration đầu tiên                      |
| Seed không deterministic                   | Dùng stable UUID                                        |
| Không có fallback khi Supabase lỗi         | Dual-source mode                                        |

---

## 12. Migration Workflow

```
1. Codex thiết kế schema → review
2. Command Code viết migration SQL
3. Codex review migration (RLS, indexes, constraints)
4. Chạy migration local: supabase db push / migration up
5. Command Code viết TypeScript types
6. Codex review types
7. Command Code viết data layer + cache + adapters
8. Chạy typecheck + lint
9. Test với CONTENT_SOURCE_MODE=local (đảm bảo không break)
10. Test với CONTENT_SOURCE_MODE=dual (verify Supabase hoạt động)
11. Seed dữ liệu test
12. Codex verify end-to-end
```

---

Tài liệu này dựa trên codebase Feaon-ldp-v2, commit `b994055`. Các pattern và workflow được trích xuất từ code thực tế đã chạy trên production.
