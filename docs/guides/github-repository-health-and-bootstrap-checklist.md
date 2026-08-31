# GitHub Repository Health and Bootstrap Checklist

## Purpose

Checklist chuẩn để audit “GitHub health” của một repository và bộ bước bootstrap để đưa repo mới (hoặc repo cũ thiếu metadata) đạt `community health 100%` như đã thực hiện cho `agy-workflow`, `codex-workflow`, `opencode-workflow`, `openclaw-setup`, `workflow-playbooks` (ngoại trừ `qvak-portfolio`, `Feaon-ldp-v2`).

Bao phủ các tín hiệu mà GitHub Community Profile đánh giá và người dùng nhìn thấy ở mục **About**: description, topics, license, README, CONTRIBUTING, Code of Conduct, Security policy, issue/PR templates, package metadata và contributor visibility.

## When to use

- Khi tạo repo mới và muốn setup đầy đủ ngay từ đầu.
- Khi audit định kỳ các repo cá nhân/tổ chức (ví dụ trước khi public, trước release).
- Khi GitHub hiển thị `health_percentage < 100%` hoặc `files.license = null`.
- Khi onboard project mới vào workflow chung (`agy-workflow`/`opencode-workflow`/`codex-workflow`).

## Preconditions

- Có quyền `admin`/`maintain` trên repo (để PATCH description/topics).
- Đã cài `gh` CLI và đăng nhập: `gh auth status` phải `Logged in` với token có scope `repo`.
- Local clone đã có `user.name`/`user.email` (vd `audition-mld <293917115+audition-mld@users.noreply.github.com>`).
- Quyết định license chung (chuẩn hiện tại: `MIT 2026 Quách Võ Anh Khoa (khoawatt)`; private repo có thể ghi `MIT 2026 Quách Võ Anh Khoa (khoawatt) / Akbi47`).

## Workflow

### 1) Audit hiện trạng (read-only)

Chạy audit cho từng repo cần kiểm — ví dụ batch 5 repo cá nhân:

```bash
for repo in khoawatt/agy-workflow khoawatt/codex-workflow khoawatt/opencode-workflow khoawatt/openclaw-setup khoawatt/workflow-playbooks; do
  echo "===== $repo ====="
  gh api "repos/$repo" --jq '{name, description, homepage, license: .license.spdx_id, topics, visibility, has_issues, has_wiki, default_branch}'
  gh api "repos/$repo/community/profile" --jq '{health_percentage, files: {license: .files.license.html_url, contributing: .files.contributing.html_url, code_of_conduct: .files.code_of_conduct.html_url, readme: .files.readme.html_url, pr_template: .files.pull_request_template.html_url}}'
  gh api "repos/$repo/contents/LICENSE" --jq .name 2>&1 | head
  gh api "repos/$repo/contents/CONTRIBUTING.md" --jq .name 2>&1 | head
  gh api "repos/$repo/contents/CODE_OF_CONDUCT.md" --jq .name 2>&1 | head
done
```

Kiểm local (chưa push):

```bash
for d in agy-workflow codex-workflow opencode-workflow openclaw-setup workflow-playbooks; do
  echo "===== $d ====="
  git -C "/home/audition/projects/personal/$d" remote -v | head -n 2
  git -C "/home/audition/projects/personal/$d" status --porcelain | head -n 20
  ls -l "/home/audition/projects/personal/$d/LICENSE" "/home/audition/projects/personal/$d/CONTRIBUTING.md" 2>&1 | head
  cat "/home/audition/projects/personal/$d/package.json" 2>&1 | head -n 20
done
```

### 2) Checklist — 12 mục phải đạt

| # | Mục | Tín hiệu GitHub | Cách kiểm | Tiêu chuẩn đạt |
|---|-----|----------------|-----------|----------------|
| 1 | **About — Description** | `repos/{owner}/{repo}.description` | `gh api repos/$repo --jq .description` | 1 câu rõ ràng, không `null`, mô tả đúng chức năng (vd `codex-workflow: Portable tmux launcher ...`) |
| 2 | **About — Website/Homepage** | `.homepage` | `gh api repos/$repo --jq .homepage` | Để `null` hoặc URL hợp lệ (không để placeholder) |
| 3 | **About — Topics** | `.topics` | `gh api repos/$repo --jq .topics` | 3–7 topics, lowercase, đã `PUT /topics` (vd `opencode-workflow: opencode,chatgpt,gemini,ai-agent,code-review,playwright`) |
| 4 | **LICENSE** | `community/files.license` + `license.spdx_id` | `gh api repos/$repo/license` + `ls LICENSE` | File `LICENSE` MIT ở root, `spdx_id: MIT`, community health nhận diện |
| 5 | **README.md** | `community/files.readme` | `gh api repos/$repo/contents/README.md` | Có `## Contributing`, `## Authors & Contributors`, `## License`, `## Security` (link tới file tương ứng) |
| 6 | **CONTRIBUTING.md** | `community/files.contributing` | `ls CONTRIBUTING.md` | Hướng dẫn setup, PR guidelines, link CODE_OF_CONDUCT/SECURITY, ghi Author & Maintainer |
| 7 | **CODE_OF_CONDUCT.md** | `community/files.code_of_conduct` | `ls CODE_OF_CONDUCT.md` | Dựa trên Contributor Covenant 2.1, nêu contact `@khoawatt`/`@Akbi47` |
| 8 | **SECURITY.md** | (health, không hiện trực tiếp trong community/files nhưng được tính) | `ls SECURITY.md` | Bảng Supported Versions + hướng dẫn private advisory (`/security/advisories/new`), lưu ý secrets-free |
| 9 | **.github/pull_request_template.md** | `community/files.pull_request_template` | `ls .github/pull_request_template.md` | Gồm Description/Changes/Verification checklist |
| 10 | **.github/ISSUE_TEMPLATE/** | `community/files.issue_template` | `ls .github/ISSUE_TEMPLATE/` | Ít nhất `bug_report.yml` và `feature_request.yml` (GitHub Forms) |
| 11 | **package.json (nếu là Node/JS repo)** | Không tính health nhưng ảnh hưởng About & discoverability | `cat package.json` | Có `name`, `description` (= repo description), `repository.url`, `keywords` (trùng topics), `author`, `license: MIT`, `scripts.test` |
| 12 | **Contributors & Visibility** | `contributors_url` + `visibility` | `git log --format="%an <%ae>" | sort -u` và `gh api repos/$repo --jq .visibility` | `git log` ghi đúng Author (không anonymous), README liệt kê Authors, `visibility` đúng ý đồ (public vs private), `has_issues: true` |

> Lưu ý các repo đã chuyển owner (ví dụ `Akbi47/openclaw-setup` → `khoawatt/openclaw-setup`): luôn kiểm tra `git remote -v` và sửa `git remote set-url origin https://github.com/khoawatt/<repo>.git` để push không lệch owner.

Trường hợp đặc biệt: thư mục như `ai-os-v1.6` chỉ chứa `ai-os-v1.6.zip` và không có `.git` — không audit được bằng `gh api`; cần `git init` + tạo repo mới nếu muốn đưa lên GitHub.

### 3) Bootstrap / Khắc phục (áp dụng cho 1 project mới)

Thực hiện theo thứ tự dưới đây — chính là các bước đã chạy cho 4 repo ngày 2026-08-31 (health từ 14–28% → 100%):

#### 3.1 Sửa metadata GitHub (About)

```bash
# Description (ví dụ codex-workflow)
gh api "repos/khoawatt/codex-workflow" --method PATCH \
  --field description="Portable tmux launcher and onboarding docs for running Codex across multiple projects with ChatGPT and Gemini web bridges"

# Topics — PUT toàn bộ danh sách (ghi đè)
gh api "repos/khoawatt/codex-workflow/topics" --method PUT \
  --input - <<< '{"names": ["codex","tmux","chatgpt","gemini","ai-agent","workflow","playwright"]}'

# Mẫu cho các repo khác:
# opencode-workflow → ["opencode","chatgpt","gemini","ai-agent","code-review","playwright"]
# openclaw-setup   → ["openclaw","opencode","ai-agent","automation","bootstrap"]
# workflow-playbooks → ["documentation","engineering","playbook","runbook","workflow"]
```

#### 3.2 Thêm file community ở local

Tạo từ template chuẩn (đã chuẩn hóa ở `agy-workflow`):

- `LICENSE` — MIT, copy từ `agy-workflow/LICENSE` (đổi copyright nếu cần):
  ```
  MIT License
  Copyright (c) 2026 Quách Võ Anh Khoa (khoawatt)
  ...
  ```
- `CONTRIBUTING.md` — clone từ `agy-workflow/CONTRIBUTING.md` rồi sửa phần Development Setup / PR Guidelines cho đúng repo (ví dụ `codex-workflow` cần `codex-work --status`, `openclaw-setup` cần `verify-no-secrets.sh`).
- `CODE_OF_CONDUCT.md` — bản rút gọn Covenant 2.1 (như đã tạo cho 4 repo).
- `SECURITY.md` — bảng Supported Versions + advisory link `https://github.com/<owner>/<repo>/security/advisories/new` + lưu ý secrets-free.
- `.github/pull_request_template.md`:
  ```md
  ## Description
  ## Changes
  - 
  ## Verification
  - [ ] Ran `bash tests/test.sh` successfully
  - [ ] Verified local workflow execution
  ```
- `.github/ISSUE_TEMPLATE/bug_report.yml` và `feature_request.yml` — copy từ `agy-workflow/.github/ISSUE_TEMPLATE/` và đổi `description` cho đúng tên repo.

#### 3.3 Sửa README

Thêm vào cuối README (sau mục an toàn/tài liệu):

```md
---

## Đóng góp (Contributing)

Mọi đóng góp đều được hoan nghênh. Vui lòng xem [CONTRIBUTING.md](CONTRIBUTING.md) và [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## Tác giả & Contributors

* **Quách Võ Anh Khoa** ([@khoawatt](https://github.com/khoawatt)) — Author & Maintainer
* **Audition MLD** ([@audition-mld](https://github.com/audition-mld)) — Contributor

---

## Giấy phép (License)

Dự án được phân phối dưới giấy phép **MIT License**. Xem [LICENSE](LICENSE).

---

## Bảo mật (Security)

Xem [SECURITY.md](SECURITY.md) để báo cáo lỗ hổng.
```

Sửa thêm `git clone` URL nếu README cũ còn `Akbi47/...` → `khoawatt/...`.

#### 3.4 package.json (nếu có)

Đồng bộ với About:

```json
{
  "name": "<repo-name>",
  "version": "1.0.0",
  "description": "<repo description — giống GitHub About>",
  "repository": { "type": "git", "url": "git+https://github.com/khoawatt/<repo>.git" },
  "keywords": ["<topics...>"],
  "author": "Quách Võ Anh Khoa <khoawatt>",
  "license": "MIT",
  "scripts": { "test": "bash tests/test.sh" }
}
```

#### 3.5 Commit & Push

```bash
git add LICENSE CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md README.md .github/ package.json
git commit -m "docs: add GitHub metadata, license, contributor guidelines and package info

- Add MIT LICENSE (2026 Quach Vo Anh Khoa)
- Add CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- Add .github pull_request_template and issue templates
- Update README with Contributing / Authors / License / Security
- GitHub topics set: <list>"
git push origin main
```

Nếu remote còn trỏ `Akbi47/...`:

```bash
git remote set-url origin https://github.com/khoawatt/<repo>.git
git push origin main
```

#### 3.6 Áp dụng cho project hoàn toàn mới (từ `git init`)

```bash
mkdir my-new-tool && cd my-new-tool
git init
gh repo create khoawatt/my-new-tool --public --description "One-line description" --source=. --remote=origin --push
# sau đó chạy lại 3.1 → 3.5; hoặc copy bộ file community từ workflow-playbooks/docs/guides này
```

## Validation

Sau khi push, chạy lại audit 1) và xác nhận:

```bash
gh api "repos/khoawatt/<repo>/community/profile" --jq '.health_percentage'
# kỳ vọng: 100
gh api "repos/khoawatt/<repo>" --jq '{license: .license.spdx_id, topics, description}'
# kỳ vọng: license MIT, topics đã set, description không null
# GitHub UI: repo → About (bên phải) hiển thị description + topics, tab Insights → Community Standards → tất cả tick xanh
```

Đã validate cho 5 repo ngày 2026-08-31:

| Repo | health trước | health sau | Commit |
|------|-------------|-----------|--------|
| agy-workflow | 71 | 100 | `ea4a7b8` |
| codex-workflow | 28 | 100 | `1962bd7` |
| opencode-workflow | 28 | 100 | `e32313a` |
| openclaw-setup | 14 | 100 | `9fc6ca1` (remote fix) |
| workflow-playbooks | 28 | 100 | `05a1936` |

## Troubleshooting

| Triệu chứng | Nguyên nhân | Cách xử lý |
|-------------|-------------|-----------|
| `gh api repos/.../license` → 404 | Thiếu `LICENSE` ở root hoặc chưa push | Thêm `LICENSE` MIT và push, đợi GitHub index 1–2 phút |
| `health_percentage` vẫn <100 sau khi thêm file | Tên file sai case (`licence`, `Contributing.md`) hoặc đặt sai thư mục (`.github` thiếu) | Đặt đúng `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/*.yml` ở root |
| `git push` báo `remote: Repository not found` | Remote còn `Akbi47/...` trong khi repo đã chuyển sang `khoawatt/...` | `git remote set-url origin https://github.com/khoawatt/<repo>.git` |
| `gh auth status` báo `Not Found` cho `Akbi47/...` | Token hiện tại không có quyền trên org cũ | `gh auth switch --user Akbi47` (token thực tế map tới `khoawatt`) rồi retry |
| `ai-os-v1.6` báo `not a git repository` | Thư mục chỉ chứa zip, chưa `git init` | Giải nén, `git init`, tạo repo mới hoặc import vào repo hiện có |

## References

- GitHub Docs — Community health files: `https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions`
- GitHub REST — Community Profile: `GET /repos/{owner}/{repo}/community/profile`
- GitHub REST — Topics: `PUT /repos/{owner}/{repo}/topics`
- Template nội bộ: `templates/playbook-template.md`, `meta/naming-conventions.md`
- Repo mẫu đã chuẩn hóa: `https://github.com/khoawatt/agy-workflow` (LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, .github)
- Checklist nguồn: kết quả audit ngày 2026-08-31 cho 5 repo cá nhân (ngoại trừ `qvak-portfolio`, `Feaon-ldp-v2`)
