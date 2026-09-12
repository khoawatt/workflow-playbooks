# ChatGPT Review Image Generation Playbook

## Purpose

Chuẩn hóa cách giao task gen/tạo ảnh (1 hoặc nhiều ảnh cùng lúc) cho `@chatgpt-review` (ChatGPT web qua Playwright bridge): đưa prompt + mô tả ảnh, chạy nền vì gen lâu, đợi hoàn tất rồi tải ảnh về và lưu vào nơi hợp lý để sử dụng. Tránh block session opencode, tránh mất ảnh, tránh lưu sai chỗ.

## When to use

- User yêu cầu `gen ảnh`, `tạo ảnh`, `vẽ ảnh`, kèm mô tả/nội dung ảnh.
- Cần gen batch nhiều ảnh trong một lần (pattern chuẩn của playbook này: **1 prompt → N ảnh**).
- Task gen ảnh dự kiến lâu (vài phút), không muốn session chính bị treo đợi.
- Sau khi có ảnh cần lưu vào repo để dùng tiếp (web assets, docs minh họa, slide, QA evidence).

## Preconditions

- Bridge đã login: `~/.config/opencode/chatgpt-bridge/bin/chatgpt-review status` phải in `"loggedIn": true`. Nếu `false` thì chạy `login` (manual, handles 2FA/CAPTCHA) hoặc `login --auto` khi `.env` đã có `CHATGPT_EMAIL/CHATGPT_PASSWORD` (`chmod 600`).
- Bridge chạy **headful** mặc định (cần display để qua Cloudflare/Google checks). Trên server headless dùng `xvfb-run` hoặc virtual display.
- Môi trường có `bash`, thư mục temp `/tmp/opencode` writable.
- Hiểu giới hạn bridge: **single Chrome profile + serialize qua lock file** (`~/.config/opencode/chatgpt-bridge/.lock`). Hai lần `ask` song song sẽ xếp hàng, không chạy thực sự song song. Vì vậy batch N ảnh luôn gộp vào **một prompt**, không bắn N `ask` đồng thời.
- Skill gốc `chatgpt-review` hiện định nghĩa cho review text (`RESULT_TEXT → VERDICT`); khi dùng để gen ảnh thì `ask` gửi prompt mô tả ảnh, không gửi theo envelope review.

## Workflow

### 1. Chuẩn bị prompt file (1 prompt → N ảnh)

Viết prompt vào file để `ask --file` đọc được, đánh số từng ảnh rõ ràng:

```bash
cat > /tmp/opencode/img-prompt.txt <<'EOF'
Tạo 3 ảnh minh họa cho landing page khóa học:
- Ảnh 1: hero banner 16:9, phong cách flat, robot thân thiện + chữ "Học AI từ số 0", nền sáng.
- Ảnh 2: square 1:1, icon-style, biểu đồ tăng trưởng trên laptop.
- Ảnh 3: portrait 3:4, ảnh chân dung giáo viên nữ đang giảng bài, ánh sáng studio.
Trả về từng ảnh riêng biệt, giữ đúng thứ tự 1→3, không gộp chung vào một ảnh.
EOF
cat /tmp/opencode/img-prompt.txt
```

Quy tắc prompt:

- Luôn ghi số lượng + tỉ lệ (`16:9`, `1:1`, `3:4`) + phong cách + nội dung chính mỗi ảnh.
- Với 1 ảnh: mô tả 1 đoạn đầy đủ, vẫn dùng file để dễ log lại.
- Không nhồi quá nhiều chi tiết mâu thuẫn vào một ảnh.

### 2. Kiểm tra trạng thái bridge trước khi gen

```bash
~/.config/opencode/chatgpt-bridge/bin/chatgpt-review status
# phải có "loggedIn": true

cd <repo-hien-tai> && ~/.config/opencode/chatgpt-bridge/bin/chatgpt-review chats
# xem key repo+branch hiện tại, tránh nhầm thread
```

- Nếu `loggedIn: false` → dừng, báo user login lại, không chạy gen.
- Muốn thread mới sạch cho batch ảnh: thêm `--new` ở lệnh `ask`.

### 3. Chạy gen nền bằng `bash & + poll` (không block session)

Vì gen ảnh có thể mất vài phút, luôn chạy nền và poll log:

```bash
BRIDGE=~/.config/opencode/chatgpt-bridge/bin/chatgpt-review
LOG=/tmp/opencode/img-gen-$(date +%Y%m%d-%H%M%S).log

nohup $BRIDGE ask --file /tmp/opencode/img-prompt.txt > "$LOG" 2>&1 &
echo $! > /tmp/opencode/img-gen.pid

echo "PID: $(cat /tmp/opencode/img-gen.pid)"
echo "LOG: $LOG"
tail -n 20 "$LOG"
```

Poll đợi hoàn tất (chạy tiếp trong session khác hoặc sau khi làm việc khác):

```bash
PID=$(cat /tmp/opencode/img-gen.pid)
LOG=$(ls -t /tmp/opencode/img-gen-*.log | head -n1)

# kiểm tra còn chạy không
if kill -0 "$PID" 2>/dev/null; then echo "RUNNING pid=$PID"; else echo "DONE pid=$PID"; fi
tail -n 40 "$LOG"

# đợi tối đa ~15 phút, check mỗi 30s
for i in $(seq 1 30); do
  kill -0 "$PID" 2>/dev/null || break
  sleep 30
  echo "--- poll $i --- $(date -u +%H:%M:%S)"
  tail -n 5 "$LOG"
done
```

- Không xóa `.lock` thủ công trừ khi PID đã chết mà lock còn (stale lock bridge tự clear).
- Không bắn batch thứ hai khi batch đầu còn `RUNNING` — bridge sẽ queue, dễ timeout nhầm.

### 4. Lấy ảnh về và lưu vào nơi hợp lý (tùy ngữ cảnh)

ChatGPT web trả ảnh trong thread; agent lấy URL/file ảnh từ output `ask` trong `$LOG`, sau đó `curl` về local. Quy ước lưu theo ngữ cảnh:

| Ngữ cảnh repo | Nơi lưu đề xuất | Ví dụ |
|---|---|---|
| Web app (Next.js/React) | `assets/generated/<yyyy-mm-dd>/` hoặc `public/images/generated/` | `assets/generated/2026-09-12/hero-01.png` |
| Docs/playbook repo | `docs/assets/<topic>/` | `docs/assets/landing/hero-01.png` |
| Task tạm / chưa chốt dùng | `/tmp/opencode/img-out/` rồi `move` khi chốt | `/tmp/opencode/img-out/batch-01/` |
| QA evidence / bug visual | cùng folder evidence của task | `docs/qa/<task-id>/` |

```bash
mkdir -p /tmp/opencode/img-out assets/generated/$(date +%F)
ls -lh /tmp/opencode/img-out/ assets/generated/$(date +%F)/

# mẫu tải khi LOG chứa URL ảnh (thay URL thật từ output ask)
curl -L "<IMAGE_URL_1>" -o "assets/generated/$(date +%F)/img-01.png"
curl -L "<IMAGE_URL_2>" -o "assets/generated/$(date +%F)/img-02.png"

ls -lh assets/generated/$(date +%F)/
```

- Tên file `lowercase-kebab-case.png/jpg`, không space/underscore, gắn số thứ tự khớp prompt (`hero-01.png`, `hero-02.png`).
- Không commit `profile/`, `chats.json`, `projects.json`, `.lock`, `.env` của bridge.

### 5. Verify ảnh bằng vision trước khi bàn giao

```bash
ls -lh assets/generated/$(date +%F)/img-*.png
```

- Dùng `read` lên từng file ảnh để model vision xác nhận đúng mô tả, đúng tỉ lệ, không lỗi chữ/mặt/tay.
- Với batch: đối chiếu ảnh 1..N với prompt đánh số ở bước 1; ảnh nào sai thì gen lại riêng bằng prompt lẻ, không gen lại cả batch.

## Validation

- [ ] `status` in `"loggedIn": true` trước khi gen.
- [ ] Có file `/tmp/opencode/img-prompt.txt` ghi rõ số lượng + mô tả từng ảnh.
- [ ] Lệnh gen chạy nền qua `&`, có `img-gen.pid` + `img-gen-*.log`, session chính không bị block.
- [ ] Poll xác nhận PID `DONE`, log chứa đủ N ảnh/URL theo thứ tự.
- [ ] `ls -lh` nơi lưu đích: mỗi file > 50KB, tên `lowercase-kebab-case`, đúng N file.
- [ ] `read` từng ảnh thành công, nội dung khớp mô tả prompt.
- [ ] `docs/index.md` không cần đổi cho task gen ảnh lẻ; chỉ đổi khi batch này là playbook/asset durable của repo.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `status` in `"loggedIn": false` | Session hết hạn / chưa login | Chạy `chatgpt-review login` (manual, xử 2FA/CAPTCHA) hoặc `login --auto` khi `.env` đã cấu hình; check lại `status` |
| `ask` treo lâu, log không ra | `.lock` đang giữ bởi run khác / Cloudflare chặn headless | `tail` log + `chats`; đợi run trước xong; trên headless dùng `xvfb-run`; không xóa lock khi PID còn sống |
| Gen batch thiếu ảnh (3 yêu cầu, về 2) | Prompt gộp ảnh, model gộp/sót | Tách mô tả đánh số `Ảnh 1/2/3`, yêu cầu "trả từng ảnh riêng, đúng thứ tự"; gen bù ảnh thiếu bằng prompt lẻ + `--new` nếu thread cũ stale |
| Ảnh sai tỉ lệ / sai style | Prompt thiếu `16:9/1:1`, thiếu style | Bổ sung tỉ lệ + style + negative ("không gộp chung", "không thêm chữ thừa") rồi gen lại ảnh đó |
| `curl` về file < 50KB chứa HTML login | URL hết hạn / cần auth | Mở lại thread `chats`, lấy URL mới từ output `ask`; không commit URL signed vào git |
| Không biết lưu ở đâu | Repo chưa có quy ước assets | Theo bảng ngữ cảnh ở bước 4; task tạm giữ ở `/tmp/opencode/img-out/`, chốt mới `move` vào `assets/generated/<date>/` |
| Muốn N prompt song song cho nhanh | Bridge single-profile serialize | Không làm vậy; luôn **1 prompt → N ảnh** trong một `ask`, xếp hàng tuần tự nếu có nhiều batch |

## References

- Skill gốc: `~/.config/opencode/skills/chatgpt-review/SKILL.md` — subcommands `ask|status|chats|reset|project`, approval `get|set|clear`, conversation reuse per repo+branch, `bridge-config.json` (`max_chars`/`max_turns`/`max_age_hours`).
- Mẫu format playbook: `docs/guides/google-docs-image-reading-guide.md` (workflow + lệnh cụ thể + bảng troubleshooting + case thực tế).
- Quy ước đặt tên: `meta/naming-conventions.md` (`lowercase-kebab-case.md`, acronym lowercased); template: `templates/playbook-template.md`.
- Case-образец: batch hero 3 ảnh landing (16:9/1:1/3:4) chạy nền `nohup ask --file … &` + poll `kill -0` + lưu `assets/generated/<date>/img-0N.png` + verify bằng `read` vision.
