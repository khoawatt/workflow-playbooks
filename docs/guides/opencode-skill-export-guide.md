# OpenCode Skill Export Guide

## Purpose

Chuẩn hóa cách tạo và xuất **skill/playbook markdown mới** vào `workflow-playbooks` chỉ bằng một lệnh opencode: `/export-skill <mô tả>`. Thay vì tự tìm folder, đặt tên, viết template và cập nhật index thủ công, agent tự động thực hiện toàn bộ pipeline và đảm bảo tuân thủ `meta/naming-conventions.md`.

## When to use

- Bạn vừa giải quyết một case mới (ví dụ: đọc Google Docs kèm ảnh, xử lý race condition, SEO fix) và muốn lưu thành playbook reusable cho các model sau.
- Bạn chỉ muốn gõ `/export-skill <1 câu mô tả>` và để agent tự tạo file đúng chỗ.
- Khi cần đảm bảo mọi playbook mới tuân thủ `templates/playbook-template.md` và được index trong `docs/index.md`.

## Preconditions

- Repo `workflow-playbooks` đã clone tại `/home/audition/projects/personal/workflow-playbooks` (hoặc path tương đương; command dùng absolute path này).
- Repo `opencode-workflow` đã cài global command: `command/export-skill.md` tồn tại và đã `bash install.sh --config` hoặc đã copy vào `~/.config/opencode/command/export-skill.md`.
- Project hiện tại có `.opencode/commands/export-skill.md` (được cài qua `bash install-project.sh <repo>` từ `opencode-workflow`).
- Đã đọc `meta/naming-conventions.md` (lowercase-kebab-case, acronym lowercased) và `templates/playbook-template.md`.

## Workflow

### 1. Gọi command

Trong session opencode bất kỳ (Feaon-ldp-v2, workflow-playbooks, repo khác):

```text
/export-skill skill đọc Google Docs kèm ảnh qua docx export
/export-skill playbook xử lý race condition khi mua hàng với Supabase Postgres
/export-skill guide audit GitHub repo health và bootstrap checklist
```

`$ARGUMENTS` là toàn bộ mô tả sau `/export-skill`.

### 2. Agent phân tích và chọn vị trí

Agent đọc `meta/naming-conventions.md` và `templates/playbook-template.md`, sau đó:

- Trích tên file: `lowercase-kebab-case.md` (ví dụ: `google-docs-image-reading-guide.md`, `supabase-postgres-race-condition-playbook.md`).
- Chọn category trong `docs/`: `ai-agents`, `architecture`, `deployment`, `guides`, `interview`, `seo` — chọn folder khớp nhất; chỉ tạo folder mới khi không có category nào phù hợp.
- Lý do chọn được ghi trong báo cáo cuối.

### 3. Tạo playbook

Tạo file tại `docs/<category>/<tên-file>.md` với cấu trúc:

```markdown
# <Title>

## Purpose
## When to use
## Preconditions
## Workflow
## Validation
## Troubleshooting
## References
```

Nội dung phải reusable, có lệnh cụ thể, bảng troubleshooting, references tới case thực tế.

### 4. Cập nhật index

Thêm 1 dòng vào `docs/index.md` bảng 5 cột:

| Document | Category | Purpose | When to use | Path |

Giữ thứ tự theo Category, không xóa dòng cũ.

### 5. Báo kết quả

Agent trả về:

- Đường dẫn file đã tạo
- Category và lý do chọn
- Dòng index đã thêm

### 6. Cài đặt global (một lần)

Nếu command chưa có global:

```bash
# Từ opencode-workflow repo
cp command/export-skill.md ~/.config/opencode/command/export-skill.md

# Hoặc cài lại toàn bộ config
bash install.sh --config

# Cài vào project mới
bash install-project.sh /path/to/your/repo
# → tạo .opencode/commands/export-skill.md trong repo đó
```

Restart opencode sau khi cài.

## Validation

- [ ] `~/.config/opencode/command/export-skill.md` tồn tại.
- [ ] `docs/<category>/<tên-file>.md` tồn tại, tên `lowercase-kebab-case.md`, nội dung có đủ 7 section template.
- [ ] `docs/index.md` có dòng mới trỏ đúng Path, Category khớp folder.
- [ ] Gọi `/export-skill` với mô tả thiếu → agent yêu cầu bổ sung thay vì tạo file rỗng.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/export-skill` báo `command not found` | Chưa cài global | `cp opencode-workflow/command/export-skill.md ~/.config/opencode/command/` rồi restart opencode |
| File tạo sai folder | Mô tả category mơ hồ | Bổ sung keyword rõ hơn trong `$ARGUMENTS` (ví dụ: `guide`, `seo`, `deployment`) |
| Tên file có underscore/UPPERCASE | Agent không đọc naming-conventions | Nhắc agent đọc `meta/naming-conventions.md` trước khi đặt tên |
| `docs/index.md` không cập nhật | Agent quên bước 4 | Yêu cầu agent chạy lại bước cập nhật index |
| Workflow-playbooks path không tồn tại | Machine khác đặt repo ở path khác | Sửa absolute path trong `command/export-skill.md` cho khớp máy đó |

## References

- Template: `workflow-playbooks/templates/playbook-template.md`
- Naming: `workflow-playbooks/meta/naming-conventions.md`
- Mẫu playbook đã tạo bằng command này: `docs/guides/google-docs-image-reading-guide.md` (case `1ZfIq...` docx + `word/media/image*.png`).
- Global command source: `opencode-workflow/command/export-skill.md` — được copy vào `~/.config/opencode/command/` qua `install.sh --config` và vào từng repo qua `install-project.sh`.
