# Paseo Desktop (Windows) ↔ WSL2 Setup Runbook

> Tài liệu cho AI agent triển khai. Đọc hết trước khi chạy, báo **PASS / FAIL / BLOCKED** sau mỗi step.
> Tested: 2026-09-20 — Ubuntu 26.04 / kernel `6.18.33.1-microsoft-standard-WSL2` / Node `v26.3.0` / npm `11.16.0` / claude `2.1.186` / codex `0.155.1` / opencode `v2.0.10` / `@getpaseo/cli@0.8.0` / daemon `0.8.0`.

## 1. Kiến trúc

```text
Windows                              WSL2 Ubuntu
┌──────────────────────┐             ┌──────────────────────────────┐
│ Paseo Desktop (UI)   │             │ sshd :2222                   │
│  → Remote SSH ───────┼──SSH────────▶  └── tunnel → Paseo daemon   │
└──────────────────────┘   127.0.0.1:2222      127.0.0.1:6767       │
                                                  │                │
                                    Claude / Codex / OpenCode      │
                                    ~/projects, Git, Node          │
                                                     └─────────────┘
```

Nguyên tắc: daemon + agents + code **đều ở WSL**. Không Docker, không cài agents lên Windows, không `wsl.exe` wrapper, không expose `6767` ra `0.0.0.0`.

## 2. Tổng quan 5 steps (tất cả trong 1 terminal WSL, trừ Step 4)

| Step | Việc | Password? |
|------|------|-----------|
| 0 | Cấp `NOPASSWD` 1 lần (hỏi password đúng 1 lần duy nhất) | có, 1 lần |
| 1 | Check env + cài Paseo CLI + start daemon | không |
| 2 | SSH server + autostart SSH + daemon chạy systemd | không |
| 3 | Tạo SSH key phía Windows (gọi từ WSL) + authorize | không |
| 4 | Paseo Desktop → Add host (thao tác tay trên Windows) | không |

## 3. Step 0 — Gỡ nút thắt `sudo` (chạy 1 lần duy nhất)

Mọi lệnh sau đều cần `sudo`. Cấp `NOPASSWD` để agent và các step sau chạy không cần interactive (chấp nhận được trên WSL dev cá nhân, không làm trên server shared):

```bash
sudo tee /etc/sudoers.d/99-$(whoami)-nopasswd >/dev/null <<EOF
$(whoami) ALL=(ALL) NOPASSWD:ALL
EOF
sudo chmod 0440 /etc/sudoers.d/99-$(whoami)-nopasswd
sudo visudo -c && sudo -n true && echo SUDO_OK
```

PASS: in ra `SUDO_OK`. Từ đây dùng `sudo -n` ở mọi nơi.

## 4. Step 1 — Env + Paseo CLI + daemon

```bash
uname -r | grep -q microsoft-standard-WSL2 && echo WSL2_OK
whoami; node --version; npm --version
for c in claude codex opencode; do command -v $c && $c --version 2>/dev/null; done
command -v paseo >/dev/null || npm install -g @getpaseo/cli   # NVM prefix user, KHÔNG sudo npm
paseo --version
paseo daemon status || paseo daemon start
curl -fsS http://127.0.0.1:6767/api/health && echo && ss -lntp | grep 6767
```

PASS: `WSL2_OK`, node/npm chạy, agents cần dùng có path Linux (không `C:\...`), daemon `running` + health `{"status":"ok",...}`.
Không reinstall Node/agent đang chạy. NVM thì không `sudo npm`.

## 5. Step 2 — SSH server + autostart (1 block duy nhất)

Block này làm 4 việc: cài sshd, config port 2222, **vô hiệu hóa `ssh.socket`** (gotcha lớn nhất — socket activation giữ port 22 khiến config 2222 bị lờ), và chuyển daemon sang systemd để tự sống lại sau reboot.

```bash
# --- 5.1 openssh-server (kèm tự vá dpkg nửa chừng) ---
sudo -n dpkg --configure -a
sudo -n apt update && sudo -n apt install -y openssh-server
sudo -n apt install -f -y   # no-op nếu hệ sạch; vá gói dở dang (vd vim/vim-runtime)

# --- 5.2 sshd chỉ nghe 2222 ---
sudo -n tee /etc/ssh/sshd_config.d/99-paseo-wsl.conf >/dev/null <<'EOF'
Port 2222
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin no
EOF
sudo -n sshd -t && echo SSHD_CONF_OK

# --- 5.3 TẮT socket activation :22, BẬT service :2222 + autostart + backup cron ---
sudo -n systemctl disable --now ssh.socket >/dev/null 2>&1 || true
sudo -n systemctl enable ssh
sudo -n service ssh restart
ss -lntp | grep 2222
(sudo -n crontab -l 2>/dev/null | grep -v 'paseo-ssh-autostart'; \
  echo "@reboot /usr/sbin/service ssh start  # paseo-ssh-autostart") | sudo -n crontab -

# --- 5.4 Chuyển Paseo daemon sang systemd user service (tự restart, sống sau reboot) ---
PASEO_BIN="$(command -v paseo)"
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/paseo-daemon.service <<EOF
[Unit]
Description=Paseo Daemon (autostart)
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=${PASEO_BIN} daemon start --foreground
Restart=always
RestartSec=5
Environment=HOME=${HOME}
Environment=PATH=${HOME}/.nvm/versions/node/$(node --version)/bin:/usr/local/bin:/usr/bin:/bin:${HOME}/.local/bin
[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
paseo daemon stop >/dev/null 2>&1 || true   # dọn daemon chạy tay + stale pid (setup-time only)
systemctl --user enable --now paseo-daemon.service
sleep 3
systemctl --user is-active paseo-daemon.service
curl -fsS http://127.0.0.1:6767/api/health && echo && paseo daemon status | head -8
```

PASS: `SSHD_CONF_OK`, `ss -lntp` thấy `:2222`, service `active`, daemon health `ok`.
Lưu ý: `ExecStart` pin Node version hiện tại — nếu đổi Node (nvm) thì chạy lại 5.4.

## 6. Step 3 — SSH key (gen phía Windows, gọi từ WSL, không cần mở PowerShell tay)

Paseo SSH chạy non-interactive nên **bắt buộc key-auth**. Key phải gen bằng `ssh-keygen` của Windows (đúng ACL) — block sau gọi `powershell.exe` từ WSL nên không cần thao tác tay:

```bash
mkdir -p ~/.cache ~/.ssh && chmod 700 ~/.ssh
cat > ~/.cache/paseo-winkey.ps1 <<'PS1'
if (-not (Test-Path $env:USERPROFILE\.ssh\id_ed25519)) { ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519 -N '""' }
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
PS1
PWSH="$(command -v powershell.exe || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)"
PUBKEY="$("$PWSH" -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w ~/.cache/paseo-winkey.ps1)" | grep '^ssh-ed25519' | tr -d '\r')"
rm -f ~/.cache/paseo-winkey.ps1
grep -qF "$PUBKEY" ~/.ssh/authorized_keys 2>/dev/null || echo "$PUBKEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys && echo KEY_AUTHORIZED

# test login không password, đi từ phía Windows ($USER = Linux user)
cat > ~/.cache/paseo-keytest.ps1 <<PS1
ssh -p 2222 -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new $USER@127.0.0.1 "echo SSH_KEY_OK"
PS1
"$PWSH" -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w ~/.cache/paseo-keytest.ps1)"
rm -f ~/.cache/paseo-keytest.ps1
```

PASS: thấy `KEY_AUTHORIZED` và `SSH_KEY_OK` (không hỏi password). Không ghi đè key Windows đã có, không copy private key vào WSL.

## 7. Step 4 — Paseo Desktop (tay, 1 phút, trên Windows)

`Settings → Add host → Remote SSH`, destination:

```text
ssh://<LINUX_USER>@127.0.0.1:2222
```

Bắt buộc đúng 3 điểm (rút từ lỗi thực tế):
1. Port `:2222` explicit — port 22 không còn listen.
2. Dùng `127.0.0.1`, **không** dùng `localhost` — `::1:2222` đã từng timeout trong khi `127.0.0.1` OK.
3. Paseo tunnel sẵn tới daemon `127.0.0.1:6767` phía WSL, không cần `?daemonPort=` khi daemon dùng port mặc định.

## 8. Step 5 — Verify chốt (1 block)

```bash
paseo --version; paseo daemon status | head -12
curl -fsS http://127.0.0.1:6767/api/health; echo
ss -lntp | grep -E '2222|6767'
systemctl --user is-active paseo-daemon.service
```

Rồi trong Paseo terminal (host WSL): `uname -a` → Linux WSL2; `pwd`, `git rev-parse --show-toplevel`, `command -v node/claude/codex` → toàn path `/home/...`.
Test agent read-only: *"Inspect this repo: cwd, branch, runtime. Do not modify anything."*

## 9. Troubleshooting (theo thứ tự, đừng đoán mò)

| Triệu chứng | Root cause đã gặp | Fix |
|---|---|---|
| `apt` báo `dpkg was interrupted` / `vim depends on vim-runtime` | dpkg dở dang | `sudo -n dpkg --configure -a && sudo -n apt install -f -y`, cài lại |
| `:2222` không listen, sshd vẫn nghe `:22` | `ssh.socket` còn active, giành quyền | `sudo -n systemctl disable --now ssh.socket && sudo -n service ssh restart` |
| SSH tay hỏi password / Paseo báo auth fail | thiếu key | chạy lại Step 3 |
| SSH tay OK nhưng Paseo timeout | host `localhost` dính `::1` / thiếu port | đổi URI sang `ssh://user@127.0.0.1:2222` |
| Đóng terminal xong Paseo mất kết nối | WSL đã shutdown/reboot | mở WSL 1 lần (services tự lên: `enable ssh` + cron `@reboot` + user service), verify Step 5 |
| Daemon `not_running (stale PID)` | pid cũ sau crash/reboot | `paseo daemon stop` dọn pid rồi `systemctl --user start paseo-daemon` |
| Daemon không thấy agent dù shell thấy | PATH (NVM) | so `echo $PATH` với `paseo provider diagnostic <name>`; không symlink bừa vào `/usr/local/bin` |
| Phần model OpenCode trong Paseo báo `Error` | daemon `PATH` thiếu binary + OpenCode 2.x trả 401 cho Paseo 0.8.0 | xem §14.1 (binary 1.18.31 riêng + provider override) |
| Tab profile OpenCode hiện `Terminal exited`, scrollback rỗng | prompt truyền positional bị hiểu thành đường dẫn project | xem §14.2 (revert profile về `opencode` + `--prompt={{{prompt}}}`, hard-refresh UI) |

Debug sâu: `ssh -v -p 2222 user@127.0.0.1` (Windows) → phân biệt network vs auth; `sudo journalctl -u ssh --no-pager -n 20`; `tail -n 200 ~/.paseo/daemon.log`.

## 10. Vận hành sau setup

- WSL reboot/`wsl --shutdown`/Windows restart: mở WSL 1 lần → sshd + daemon tự lên. Không chạy lại setup.
- Đổi Node version: chạy lại mục 5.4 để unit file trỏ đúng binary.
- Daemon relay mặc định bật (`wss://relay.paseo.sh:443`) — SSH là đường chính cùng máy, relay chỉ là fallback.
- Không expose `6767` ra `0.0.0.0`. Quyền chuẩn: `chmod 700 ~/.ssh`, `chmod 600 ~/.ssh/authorized_keys`.

## 11. Acceptance (PASS toàn bộ mới xong)

```text
[ ] SUDO_OK (sudo -n không hỏi password)
[ ] node/npm/agents chạy, path Linux
[ ] paseo daemon status = running, listen 127.0.0.1:6767, health ok
[ ] ss thấy :2222 (sshd) và :6767 (daemon)
[ ] paseo-daemon.service active + enabled
[ ] ssh Windows → WSL không cần password (SSH_KEY_OK)
[ ] Paseo Desktop add ssh://user@127.0.0.1:2222 → connected
[ ] terminal Paseo: uname WSL2, path /home/..., agent đọc repo Linux OK
```

## 12. Report template

```markdown
## Paseo WSL Setup Result
- Env: <distro / user / node / npm / paseo / ssh-port>
- Providers: Claude <PASS/FAIL path> / Codex <…> / OpenCode <…>
- Daemon: <running?> <listen> <PID> <relay?>
- SSH: Windows→WSL <PASS/FAIL> / key-auth <PASS/FAIL>
- Paseo Desktop: host added <y/n> / connected <y/n>
- Runtime: <uname / pwd / git-root / node-path / agent-path>
- Changes: <packages / configs / services+cron>
- Remaining: <…>
- Final: PASS / PARTIAL / BLOCKED
```

## 13. References

- Repo: https://github.com/getpaseo/paseo
- CLI: https://github.com/getpaseo/paseo/blob/main/public-docs/index.md · connectivity: `…/public-docs/connectivity.md` · config: `…/public-docs/configuration.md` · cli/diagnostic: `…/public-docs/cli.md` · ssh transport: `…/docs/development.md`
- OpenCode↔Paseo 401 incompatibility: https://github.com/getpaseo/paseo/issues/1159

## 14. OpenCode: fix lỗi model + terminal profile `terminal exited` (2026-09-20, append-only)

> Mục này chỉ ghi thêm thay đổi kỹ thuật đã áp dụng để tracking. Không sửa các mục 1–13.

### 14.1. Lỗi model OpenCode trong Paseo (provider báo `Error`)

Triệu chứng: phần model OpenCode trong Paseo báo `Error`; `paseo provider diagnostic opencode` cho `Resolved path: not found`.

Root cause (2 lớp, đã xác minh trên đúng máy này):
1. Daemon `PATH` (`...:/usr/local/bin:/usr/bin:/bin:~/.local/bin`) không chứa `~/.opencode/bin` nên không resolve được binary `opencode`.
2. Sau khi resolve được, OpenCode `v2.0.10` tự bật password cho `opencode serve` → endpoint `/provider` trả HTTP `401` khi Paseo `0.8.0` gọi không kèm credential (upstream issue getpaseo/paseo#1159). Đã tái hiện: cùng endpoint, `1.18.31` trả HTTP `200` (4 provider, 7.889 model), `2.0.10` trả `401`.

Thay đổi đã áp dụng (giữ nguyên bản chính `v2.0.10` của user tại `~/.opencode/bin/opencode`):
- Tải OpenCode `1.18.31` riêng cho Paseo: `~/.local/bin/opencode-paseo-1.18.31` (binary release chính thức, checksum khớp).
- Ghim riêng provider trong `~/.paseo/config.json`:
  ```json
  { "agents": { "providers": { "opencode": { "command": ["/home/audition/.local/bin/opencode-paseo-1.18.31"], "enabled": true } } } }
  ```
- `paseo reload` (+ restart daemon 1 lần để bỏ cache binary cũ).

Verify: diagnostic `Version: 1.18.31`, Auth 4 credentials (`~/.local/share/opencode/auth.json`: DeepSeek / Google / OpenCode Go / OpenCode Zen), `Models: 143`, `Status: Ready`.

### 14.2. Terminal profile OpenCode `terminal exited`

Triệu chứng: click profile OpenCode trong menu terminal của Paseo → tab `opencode --auto` hiện `Terminal exited` (dòng đỏ dưới cùng), scrollback rỗng (0 dòng), gửi phím không phản hồi. Terminal shell thường trong Paseo vẫn mở bình thường.

Root cause: profile custom trong `~/.paseo/config.json` là `command: "opencode --auto"` + `args: ["{{{prompt}}}"]` — prompt bị truyền **positional**. Cả OpenCode `1.18.31` (`opencode [project]`) lẫn `2.0.10` (`opencode [directory]`) đều hiểu positional là **đường dẫn project**, không phải prompt:
- `1.18.31`: `Error: Failed to change directory to .../hello`, process thoát ngay.
- `2.0.10`: `ERROR: ENOENT ... chdir ... -> 'hello'`, exit code 1.
Đã tái hiện cả hai trong PTY của Paseo. Trong khi đó default gốc của Paseo `0.8.0` (mò từ web-UI bundle `web/index-*.js`: `{id:"opencode", command:"opencode", args:[`--prompt=${o}`]}`) dùng đúng flag `--prompt` của dòng 2.x.

Thay đổi đã áp dụng (revert profile về dạng mặc định của Paseo, giữ nguyên `id` custom `profile_mu9mba45_33p3h53f0c2`):
- `~/.paseo/config.json` → profile OpenCode: `command: "opencode"`, `args: ["--prompt={{{prompt}}}"]`.
- Symlink cho daemon `PATH`: `~/.local/bin/opencode` → `/home/audition/.opencode/bin/opencode` (`v2.0.10`, bản hỗ trợ `--prompt`). Thư mục `~/.local/bin` đã nằm trong daemon `PATH` và trong systemd unit (mục 5.4).
- `paseo reload`. Provider override (mục 14.1) không đổi — terminal và provider cố ý dùng 2 binary khác nhau.

Verify trong PTY Paseo (đúng 2 dạng lệnh profile sẽ spawn): `opencode --prompt=` và `opencode --prompt=hello` đều sống (bị `timeout` kill sau 5s, RC=124 = process vẫn chạy, không exit).

### 14.3. Gotcha: Paseo web cache terminalProfiles ở phía client

- Web UI gửi `create_terminal_request` kèm `command`+`args` đã expand sẵn từ config mà UI fetch lúc load trang. Sửa file config + `paseo reload` là chưa đủ — phải **hard-refresh trang Paseo (Ctrl+Shift+R)** rồi mới click lại profile.
- Nút `Edit profiles` trong UI gọi `set_daemon_config` và ghi đè cả file `~/.paseo/config.json` bằng bản cache cũ → đã từng xóa mất fix 1 lần trong lúc sửa. Quy trình an toàn: sửa file → `paseo reload` → hard-refresh UI → mới đụng vào `Edit profiles`/click profile.
- Các tab chết cũ (scrollback 0 dòng): `paseo terminal kill` báo success nhưng daemon vẫn liệt kê tombstone → đóng tay bằng nút X trong UI.

### 14.4. Trạng thái cuối để đối chiếu khi track

- `~/.local/bin/opencode` → `~/.opencode/bin/opencode` (`v2.0.10`, cho terminal profile).
- `~/.local/bin/opencode-paseo-1.18.31` (cho provider, qua override).
- Diagnostic: `which -a opencode` OK, provider `1.18.31 / 143 models / Ready`.
- Profile OpenCode = factory default (`opencode` + `--prompt={{{prompt}}}`).
- Nếu terminal ngoài (WSL login shell) gõ `opencode --version` mà ra `1.18.31` thay vì `v2.0.10` thì do `~/.local/bin` đứng trước trong `PATH` — dùng đường dẫn đầy đủ `~/.opencode/bin/opencode` khi cần bản chính.
