# Documentation Index

Central index for every Markdown document in this library. Each entry states
the document's purpose and when to open it, so the library stays findable as it
grows.

| Document | Category | Purpose | When to use | Path |
|---|---|---|---|---|
| ChatGPT–Codex Collaboration Playbook | AI Agents | Workflow phối hợp ChatGPT Web, Codex CLI, GitHub và người phụ trách repo, lấy GitHub làm nguồn sự thật chung | Khi thiết lập workflow AI-agent, lập plan/handoff, review code, audit sau merge | [docs/ai-agents/chatgpt-codex-collaboration-playbook.md](./ai-agents/chatgpt-codex-collaboration-playbook.md) |
| Supabase + Next.js Coding Agent Guide | AI Agents | Patterns và workflow dùng Supabase trong Next.js cùng coding agent: dual-source, client setup, RLS, cache, seeding, migration | Khi làm việc với Supabase/Next.js cùng coding agent, thiết kế schema/RBAC, debug content source | [docs/ai-agents/supabase-nextjs-coding-agent-guide.md](./ai-agents/supabase-nextjs-coding-agent-guide.md) |
| Feaon Native Admin CMS Architecture | Architecture | Issue A: canonical architecture và kế hoạch pha cho Native Admin CMS trong Feaon (docs-only) | Khi bắt đầu triển khai `/admin`, review thiết kế CMS, lập kế hoạch phase/PR | [docs/architecture/feaon-native-admin-cms-architecture.md](./architecture/feaon-native-admin-cms-architecture.md) |
| Web Application Deployment Runbook | Deployment | SOP deploy web app lên VPS/server cho agentic AI: discovery, bootstrap server, runtime/secrets, Nginx/TLS, release/rollback | Khi deploy hoặc chuyển app lên server mới, audit deployment, cần checklist nghiệm thu | [docs/deployment/web-application-deployment-runbook.md](./deployment/web-application-deployment-runbook.md) |
| Agile & Scrum 22 Interview Questions | Interview | 22 câu hỏi phỏng vấn Agile/Scrum cho Backend/Fullstack 1.5–3 năm: ý chính, trả lời mẫu, lỗi cần tránh | Khi ôn phỏng vấn, luyện trả lời theo tình huống dự án thật | [docs/interview/agile-scrum-22-interview-questions.md](./interview/agile-scrum-22-interview-questions.md) |
| Feaon Production SEO, Search Console, Analytics & Ads Tech-Check Plan | SEO | Kế hoạch executable để Codex verify SEO production và chuẩn bị GSC/Analytics/Ads, phân tách CODEX-CAN-DO và HUMAN-ONLY | Khi audit SEO production, chuẩn bị Search Console/Analytics/Ads, cần baseline evidence | [docs/seo/feaon-production-seo-gsc-analytics-ads-tech-check-plan.md](./seo/feaon-production-seo-gsc-analytics-ads-tech-check-plan.md) |
| Feaon SEO Configuration & Maintenance Guide | SEO | Tài liệu durable về SEO implementation và production ops của Feaon: route registry, canonical/hreflang, sitemap, robots, structured data | Khi sửa metadata/routes/sitemap, thêm trang localized, xử lý noindex/canonical | [docs/seo/feaon-seo-configuration-and-maintenance-guide.md](./seo/feaon-seo-configuration-and-maintenance-guide.md) |

## Quick Navigation

- [AI Agents](./ai-agents/)
- [Architecture](./architecture/)
- [Deployment](./deployment/)
- [Interview](./interview/)
- [SEO](./seo/)
- [Skills](../skills/)
- [Templates](../templates/)
- [Meta](../meta/)

## Conventions

Before adding a document, read the [naming conventions](../meta/naming-conventions.md)
and start from the [playbook template](../templates/playbook-template.md).
