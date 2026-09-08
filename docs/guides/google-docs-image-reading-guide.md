# Google Docs Image Reading Guide

## Purpose

Đảm bảo mọi AI coding agent khi được gửi link Google Docs đều đọc được **full text + ảnh/screenshot** trong Docs, thay vì chỉ đọc text export bị mất ảnh. Playbook này chuẩn hóa cách bypass giới hạn của `webfetch` (text-only, 5MB limit) bằng `export?format=docx` + giải nén local.

## When to use

- Người dùng gửi link `https://docs.google.com/document/d/<id>/edit?tab=t.0` kèm mô tả "có ảnh mô tả lỗi / screenshot".
- Agent cần verify bug visual, layout, display config nhưng `webfetch` trả về text trắng hoặc bị truncate.
- Bất kỳ task nào mà Docs chứa decision/screenshot quan trọng không thể mất (bug report, design spec, QA evidence).

## Preconditions

- Docs phải ở quyền **Anyone with the link — Viewer** (nếu Restricted thì `curl` cũng 401).
- Môi trường có `curl`, `unzip`/`python3 zipfile`, thư mục temp `/tmp/opencode` writable.
- Không cần `supabase login` hay hosted credentials.

## Workflow

### 1. Thử `webfetch` trước (fast path)

```text
GET https://docs.google.com/document/d/<DOC_ID>/export?format=txt&tab=t.0
GET https://docs.google.com/document/d/<DOC_ID>/export?format=txt
```

- Nếu trả về đủ text và user xác nhận không có ảnh quan trọng → dùng luôn.
- Nếu trả về trắng / mất ảnh / `Response too large` → chuyển sang bước 2.

### 2. Fetch full docx kèm ảnh (canonical)

```bash
curl -L "https://docs.google.com/document/d/<DOC_ID>/export?format=docx&tab=t.0" \
  -o "/tmp/opencode/ggdoc-<shortId>.docx"

ls -lh /tmp/opencode/ggdoc-<shortId>.docx

python3 -c "
import zipfile, os
z = zipfile.ZipFile('/tmp/opencode/ggdoc-<shortId>.docx')
print('\n'.join(z.namelist()[:80]))
print([n for n in z.namelist() if n.startswith('word/media/')])
"

python3 -c "
import zipfile, os
z = zipfile.ZipFile('/tmp/opencode/ggdoc-<shortId>.docx')
os.makedirs('/tmp/opencode/ggdoc-img', exist_ok=True)
[z.extract(n, '/tmp/opencode/ggdoc-img') for n in z.namelist() if n.startswith('word/media/')]
"
ls -lh /tmp/opencode/ggdoc-img/word/media/
```

- `word/media/image1.png ... imageN.png` là toàn bộ screenshot trong Docs.
- Nếu `curl` trả về HTML login page (file < 50KB, chứa `accounts.google.com`) → báo user mở quyền Viewer.

### 3. Đọc text + ảnh

- Đọc text gốc vẫn cần: `word/document.xml` chứa full text (có thể `grep` hoặc `pandoc` nếu cần).
- Đọc ảnh: dùng `read` tool trên từng `/tmp/opencode/ggdoc-img/word/media/image*.png` (vision-capable model sẽ nhận base64).
- Với Docs dài > 5MB, **không** dùng `webfetch?format=html` — luôn dùng `format=docx`.

### 4. Phân tích visual (nếu có ảnh bug/layout)

- Không tự đoán — delegate cho `@vision` subagent khi cần phân tích bố cục, cắt xén, overlap.
- Prompt mẫu cho subagent:

```text
Bạn là @vision — chỉ phân tích visual, không sửa code.
Đọc 3 ảnh ở /tmp/opencode/ggdoc-img/word/media/:
- image1.png: display config
- image2.png, image3.png: bug components
Mô tả: lề bị cắt chỗ nào, element nào che, viewport hẹp/rộng, breakpoint nào gây vỡ.
Chỉ trả về phân tích.
```

### 5. Tổng hợp và trả lời

- Luôn nêu rõ: ảnh nào tương ứng component nào, config scale/resolution logic (`2560/200% = 1280`).
- Nếu không đọc được ảnh → yêu cầu user paste ảnh trực tiếp vào chat hoặc mô tả lại.

## Validation

- [ ] `ls -lh /tmp/opencode/ggdoc-*.docx` > 50KB (không phải HTML login).
- [ ] `word/media/image*.png` tồn tại và `read` thành công (Image read successfully).
- [ ] Text từ `webfetch?format=txt&tab=t.0` khớp với nội dung trong `word/document.xml` (không bị lệch tab).
- [ ] Nếu có ảnh bug: đã có report vision với vị trí cắt xén cụ thể.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `webfetch` trả về 3 dòng trắng | Docs chỉ có ảnh, text bị truncate | Dùng `export?format=docx` như bước 2 |
| `Response too large (exceeds 5MB limit)` | `format=html` quá lớn | Không dùng html, chỉ dùng `format=docx` + `format=txt` |
| `curl` ra file 10-20KB chứa `ServiceLogin` | Docs đang Restricted | Yêu cầu user chuyển sang Anyone with the link — Viewer |
| `word/media` rỗng | Docs không có ảnh embed (ảnh là linked, không embed) | Yêu cầu user paste ảnh hoặc export PDF |
| `tab=t.0` trả về sai tab | Google Docs tab param chỉ work với `export?format=docx&tab=t.0` hoặc `export?format=txt&tab=t.0` | Luôn giữ `&tab=t.0` khi user share link có `?tab=t.0` |

## References

- Case thực tế: Feaon LDP Docs `1ZfIqAGjiuWDVF2yM7eDGrfOQwLwHQ4Bf23NJRDBSpeo` tab `t.0` — 3 ảnh: Scale 200% / 2560×1600, AiSection (`AiSharedPanel.tsx:18` vw break-out), `WhyBusinessNeedWebsiteSection` (`ServiceFeatureReasonsSection.tsx:98` xl translate -24).
- Fix tương ứng: `mx-auto max-w-[min(94vw,1600px)]`, hạ `z-[100]→z-0` + thu nhỏ robot, `xl:-translate-x-24→xl:-translate-x-3`, `overflow-hidden→overflow-clip`.
- Tool: `bash` + `curl` + `python3 zipfile` + `read` (vision), `@vision` subagent cho phân tích layout.
