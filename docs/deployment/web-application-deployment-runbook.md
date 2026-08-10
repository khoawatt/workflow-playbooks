# Quy trình chuẩn deploy Web Application lên VPS/Server dành cho Agentic AI

> **Mục tiêu:** cung cấp một SOP (Standard Operating Procedure) để agentic AI có thể phân tích, lập kế hoạch, triển khai, kiểm tra, rollback và bàn giao một web application trên hầu hết máy chủ Linux như AWS EC2, Lightsail, DigitalOcean, Vultr, Hetzner, Linode, VPS truyền thống hoặc máy chủ riêng.
>
> **Phạm vi mặc định:** một máy chủ Ubuntu/Debian, một môi trường production, tên miền riêng, Nginx làm reverse proxy, HTTPS bằng Let's Encrypt và ứng dụng chạy bằng Docker Compose, PM2 hoặc systemd.

---

## 1. Nguyên tắc bắt buộc đối với agentic AI

Agent phải tuân thủ các nguyên tắc sau trong toàn bộ quá trình deploy:

1. **Không thực thi mù.** Phải kiểm tra repository, runtime, kiến trúc CPU, biến môi trường, cổng chạy, lệnh build và lệnh start trước khi thay đổi server.
2. **Không coi `dev` là production.** Ứng dụng phải vượt qua bước cài dependency, test, lint và production build theo khả năng của repository.
3. **Không làm việc hằng ngày bằng `root`.** `root` chỉ dùng để bootstrap hệ thống hoặc thực hiện tác vụ quản trị cần thiết.
4. **Không mở trực tiếp cổng ứng dụng ra Internet.** Cổng nội bộ như `3000`, `8000`, `8080` phải bind vào `127.0.0.1` hoặc private network; Internet chỉ đi qua `80/443`.
5. **Không commit hoặc in secrets vào log.** Secrets phải nằm ngoài Git và được cấp quyền truy cập tối thiểu.
6. **Không thay đổi SSH trước khi xác nhận phiên đăng nhập mới hoạt động.** Luôn giữ phiên SSH hiện tại và mở một phiên thứ hai để kiểm tra trước khi tắt root/password login.
7. **Không reload/restart Nginx khi cấu hình chưa qua `nginx -t`.**
8. **Không xin chứng chỉ TLS trước khi DNS đã phân giải đúng về server.**
9. **Không ghi đè bản release đang chạy nếu chưa có phương án rollback.**
10. **Không báo deploy thành công chỉ vì command exit code bằng 0.** Phải kiểm tra URL, health check, process, log, TLS và khả năng khởi động lại.
11. **Dừng khi gặp lỗi tại quality gate.** Không tiếp tục sang bước sau nếu gate hiện tại chưa đạt hoặc chưa có quyết định xử lý rõ ràng.
12. **Mọi thay đổi quan trọng phải có evidence.** Ghi lại commit SHA, lệnh đã chạy, file đã thay đổi, trạng thái service và kết quả smoke test.

---

## 2. Kiến trúc mục tiêu mặc định

```text
Người dùng Internet
        |
        v
DNS: app.example.com -> Public IP cố định
        |
        v
Cloud Firewall / Security Group
Chỉ mở: SSH giới hạn, HTTP 80, HTTPS 443
        |
        v
Host Firewall: UFW/nftables
        |
        v
Nginx :80/:443
TLS termination + HTTP/2 + reverse proxy
        |
        v
127.0.0.1:<APP_PORT>
Docker container / PM2 / systemd
        |
        +--> Database / Object Storage / External APIs
```

Quy trình này tách thành hai lớp:

- **Lớp hạ tầng:** VPS, IP, SSH, firewall, DNS, Nginx, TLS, backup.
- **Lớp ứng dụng:** source code, dependency, build, runtime, process manager, secrets, health check, release và rollback.

---

## 3. Hợp đồng đầu vào bắt buộc

Trước khi triển khai, agent phải thu thập hoặc suy luận có bằng chứng các trường sau:

```yaml
provider: aws-ec2 | lightsail | digitalocean | vultr | hetzner | generic-vps
region: <region-or-datacenter>
server_os: <distribution-and-version>
server_arch: amd64 | arm64
server_ip: <public-ip>
static_ip: true | false

ssh:
  user: <initial-user>
  port: 22
  private_key_path: <local-path-or-managed-credential>
  allowed_source_cidr: <trusted-ip-or-vpn-cidr>

application:
  name: <app-name>
  repository: <git-url>
  branch: main
  commit: <optional-fixed-sha>
  type: static | node | nextjs | python | java | go | php | other
  deploy_mode: docker-compose | native-process | static-files
  runtime_version: <version-from-project>
  package_manager: npm | pnpm | yarn | bun | maven | gradle | pip | poetry | other
  app_port: 3000
  health_path: /health
  build_command: <command>
  start_command: <command>

domain:
  primary: app.example.com
  aliases: []
  dns_provider: <provider>
  canonical_host: app.example.com
  http2: required | optional | disabled

environment:
  name: production
  secrets_source: <secret-manager-or-secure-file>
  env_file_path: <server-path>

deployment:
  app_user: deploy
  app_root: /srv/<app-name>
  retain_releases: 5
  backup_before_deploy: true
  database_migrations: none | manual | command
```

### 3.1 Thông tin không được tự đoán

Agent phải hỏi lại hoặc dừng nếu thiếu một trong các dữ liệu sau:

- Server/IP đích hoặc quyền tạo server.
- Repository/branch/commit cần deploy.
- Domain chính nếu yêu cầu HTTPS.
- Nguồn secrets production.
- Lệnh migration có ảnh hưởng dữ liệu.
- Quyền thực hiện thao tác phá hủy, reboot, đổi firewall hoặc thay DNS.

---

## 4. Cây quyết định chọn phương thức deploy

| Loại ứng dụng | Phương thức ưu tiên | Process/runtime |
|---|---|---|
| HTML/CSS/JS tĩnh | `static-files` | Nginx phục vụ trực tiếp |
| Next.js SSR / Node.js API | `docker-compose` nếu repo hỗ trợ; nếu không dùng `native-process` | Container, PM2 hoặc systemd |
| Python API | Docker hoặc systemd | Gunicorn/Uvicorn qua systemd |
| Java/Spring | Docker hoặc systemd | JAR qua systemd |
| Go | Docker hoặc systemd | Binary qua systemd |
| PHP | Native stack | Nginx + PHP-FPM |
| Nhiều service phụ thuộc nhau | `docker-compose` | Compose quản lý toàn bộ stack |

### 4.1 Quy tắc lựa chọn

- **Ưu tiên Docker Compose** khi cần tính tái lập, nhiều service, dependency hệ thống phức tạp hoặc deploy trên nhiều nhà cung cấp.
- **Ưu tiên native process** khi ứng dụng nhỏ, server hạn chế tài nguyên, repository đã có SOP PM2/systemd rõ ràng hoặc không được phép container hóa.
- **Không tự thêm Docker** vào repository production nếu thay đổi đó có thể ảnh hưởng kiến trúc mà chưa được review.
- **Không dùng PM2 cho runtime không phải Node.js** trừ khi dự án đã quy định rõ.
- **Ưu tiên systemd** cho binary/JAR/service native vì đây là process manager chuẩn của Linux.

---

## 5. Các quality gate tổng quát

```text
Gate 0 - Input đầy đủ
Gate 1 - Repository build được
Gate 2 - Server truy cập an toàn
Gate 3 - Runtime và secrets sẵn sàng
Gate 4 - Ứng dụng chạy được trên localhost
Gate 5 - Nginx reverse proxy hoạt động
Gate 6 - DNS và HTTPS hoạt động
Gate 7 - Smoke test, reboot test và rollback readiness đạt
Gate 8 - Bàn giao evidence hoàn tất
```

Nếu một gate thất bại, agent phải:

1. Dừng bước phụ thuộc phía sau.
2. Thu thập log và trạng thái liên quan.
3. Xác định nguyên nhân có bằng chứng.
4. Đề xuất sửa, rollback hoặc yêu cầu phê duyệt.
5. Không che giấu lỗi bằng cách bỏ test.

---

# PHẦN A - DISCOVERY VÀ PRE-DEPLOY

## 6. Phân tích repository

Agent phải kiểm tra tối thiểu:

- `README`, tài liệu deploy và source of truth của dự án.
- Manifest: `package.json`, `pyproject.toml`, `requirements.txt`, `pom.xml`, `build.gradle`, `go.mod`, `composer.json`.
- Lockfile để xác định package manager chính xác.
- `.nvmrc`, `.node-version`, `.tool-versions`, `engines`, Dockerfile hoặc Compose file.
- Lệnh `build`, `start`, `test`, `lint`, migration và seed.
- Port mặc định và khả năng cấu hình qua biến môi trường.
- Health endpoint có sẵn hay cần bổ sung.
- Thư mục static/public/upload và dữ liệu cần persist.
- Biến trong `.env.example`; phân loại public config và secret.
- Kết nối database, storage, queue, cache, SMTP và external API.
- Yêu cầu CPU architecture: `amd64` hay `arm64`.
- Yêu cầu RAM/disk tối thiểu và khả năng phát sinh swap/OOM.

### 6.1 Xác định package manager từ lockfile

| Lockfile | Package manager |
|---|---|
| `package-lock.json` | npm |
| `pnpm-lock.yaml` | pnpm |
| `yarn.lock` | Yarn |
| `bun.lock` / `bun.lockb` | Bun |

Không được tự ý chuyển package manager trong quá trình deploy.

## 7. Chạy preflight tại môi trường build

Agent dùng đúng toolchain của dự án và chạy theo thứ tự hợp lý:

```bash
# Ví dụ Node.js - thay bằng package manager thực tế
<package-manager-install-command>
<test-command>
<lint-command>
<build-command>
```

Các lệnh không tồn tại trong repository có thể bỏ qua, nhưng phải ghi rõ lý do.

### 7.1 Điều kiện đạt Gate 1

- Dependency cài thành công bằng lockfile.
- Production build thành công.
- Test/lint quan trọng không thất bại.
- Agent xác định được artifact hoặc cách khởi động production.
- Không phát hiện secret bị hard-code.
- Commit cần deploy đã được cố định bằng SHA.

## 8. Tạo deployment manifest

Trước khi vào server, agent tạo bản ghi triển khai:

```yaml
app: <app-name>
environment: production
repository: <repo-url>
branch: <branch>
commit_sha: <sha>
deploy_mode: <mode>
build_command: <command>
start_command: <command>
internal_port: <port>
domain: <domain>
requires_migration: true | false
migration_command: <command-or-none>
rollback_target: <previous-release-or-image>
```

---

# PHẦN B - CẤP PHÁT VÀ BOOTSTRAP SERVER

## 9. Tạo hoặc kiểm tra VPS/Server

Các khái niệm tương đương giữa các nhà cung cấp:

| Khái niệm chung | AWS | VPS provider khác |
|---|---|---|
| Virtual server | EC2 Instance | Droplet/Instance/VPS |
| Network firewall | Security Group | Cloud Firewall |
| Persistent disk | EBS Volume | Block Storage/Disk |
| Public IP cố định | Elastic IP | Reserved/Floating/Static IP |
| Machine image | AMI | Snapshot/Image |

Agent phải kiểm tra:

- Region gần nhóm người dùng hoặc dịch vụ phụ thuộc.
- CPU architecture tương thích với runtime/native dependency/container image.
- RAM và disk đủ cho build, log và artifact.
- Sử dụng hệ điều hành LTS còn được hỗ trợ.
- Có public IP cố định trước khi trỏ DNS.
- Disk production được mã hóa nếu nền tảng hỗ trợ.
- Cloud firewall chỉ mở đúng cổng cần thiết.
- Backup/snapshot policy phù hợp với mức độ quan trọng.
- Không tạo dịch vụ tính phí ngoài scope mà chưa được duyệt.

### 9.1 Inbound rule tối thiểu

| Port | Nguồn | Mục đích |
|---|---|---|
| SSH port | IP/VPN quản trị tin cậy | Quản trị server |
| 80/TCP | Internet | ACME challenge và chuyển hướng HTTP -> HTTPS |
| 443/TCP | Internet | HTTPS |

Không mở `3000`, `8000`, `8080`, database hoặc dashboard quản trị ra toàn Internet.

### 9.2 Chuẩn bị máy quản trị và SSH key

Trước khi thao tác với server, xác minh máy quản trị có các công cụ tối thiểu:

```bash
ssh -V
git --version
curl --version
```

Trên Windows có thể dùng OpenSSH tích hợp, Git Bash/WSL hoặc một SSH client được tổ chức cho phép như PuTTY. Agent phải ghi rõ môi trường terminal đang dùng vì cú pháp đường dẫn private key khác nhau giữa Windows, WSL và Linux/macOS.

Nếu chưa có SSH key riêng cho máy chủ production, tạo một key Ed25519 trên máy quản trị:

```bash
ssh-keygen -t ed25519 -a 64 \
  -f ~/.ssh/<app-name>-production \
  -C "<operator-or-app>-production"
```

Chuẩn hóa permission:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/<app-name>-production
chmod 644 ~/.ssh/<app-name>-production.pub
```

Kiểm tra và lấy nội dung public key để đăng ký với cloud provider hoặc server:

```bash
cat ~/.ssh/<app-name>-production.pub
```

Agent phải tuân thủ:

- Chỉ thêm **public key** có đuôi `.pub` vào cloud provider hoặc `authorized_keys`.
- Không upload, copy hoặc ghi nội dung private key lên server.
- Tách key đăng nhập server khỏi deploy key dùng để đọc repository.
- Không ghi private key vào repository, artifact, CI log hoặc prompt transcript.
- Nếu key có passphrase, dùng `ssh-agent` hoặc credential store thay vì bỏ passphrase chỉ để tự động hóa.

Nếu dùng tên key không mặc định, có thể tạo alias trong `~/.ssh/config`:

```sshconfig
Host <app-name>-production
  HostName <server-ip>
  User <initial-user-or-app-user>
  IdentityFile ~/.ssh/<app-name>-production
  IdentitiesOnly yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

Kiểm tra cấu hình đã resolve đúng trước khi kết nối:

```bash
ssh -G <app-name>-production | grep -E '^(hostname|user|identityfile) '
```

Khi cấp phát server, ưu tiên inject public key ngay từ màn hình/API tạo instance. Nếu nền tảng chỉ cấp mật khẩu ban đầu, agent phải dùng mật khẩu đúng một lần để cài public key rồi tắt password login sau khi đã xác minh phiên SSH mới.

## 10. SSH lần đầu

Ưu tiên đăng nhập bằng private key:

```bash
ssh -i <private-key-path> <initial-user>@<server-ip>
```

Nếu provider chỉ cấp mật khẩu bootstrap và chưa inject public key, có thể đăng nhập một lần bằng user mặc định của image, sau đó cài key ngay:

```bash
ssh <initial-user>@<server-ip>
```

`<initial-user>` có thể là `root`, `ubuntu`, `debian`, `ec2-user` hoặc user khác tùy image/provider; agent không được mặc định luôn là `root`. Sau khi đăng nhập, ghi nhận tối thiểu:

```bash
whoami
hostnamectl 2>/dev/null || hostname
uname -m
cat /etc/os-release
```

Agent phải xác minh fingerprint của host từ nguồn đáng tin cậy. Không tự động chấp nhận fingerprint bất thường.

> Khi gặp `REMOTE HOST IDENTIFICATION HAS CHANGED`, chỉ xóa key cũ sau khi xác nhận server vừa được reprovision hoặc IP đã được tái sử dụng. Nếu không xác nhận được, phải coi đây là rủi ro MITM và dừng.

## 11. Cập nhật hệ thống cơ bản

Trên Ubuntu/Debian:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
  ca-certificates curl git unzip jq nginx ufw
```

Nếu kernel hoặc package cốt lõi yêu cầu reboot, agent phải báo trước, xác nhận cửa sổ bảo trì và chỉ reboot khi được phép.

## 12. Tạo user deploy không phải root

```bash
sudo adduser <app-user>
sudo usermod -aG sudo <app-user>
```

Thiết lập SSH key cho user mới. Cách ưu tiên từ máy quản trị:

```bash
ssh-copy-id \
  -i ~/.ssh/<app-name>-production.pub \
  <app-user>@<server-ip>
```

Nếu `ssh-copy-id` không có sẵn, thực hiện thủ công trên server bằng public key, không dùng private key:

```bash
sudo install -d -m 700 -o <app-user> -g <app-user> /home/<app-user>/.ssh
sudo touch /home/<app-user>/.ssh/authorized_keys
sudo chown <app-user>:<app-user> /home/<app-user>/.ssh/authorized_keys
sudo chmod 600 /home/<app-user>/.ssh/authorized_keys
sudo nano /home/<app-user>/.ssh/authorized_keys
# Dán đúng một dòng public key rồi lưu.
```

Có thể chuyển sang user mới để kiểm tra môi trường login shell:

```bash
su - <app-user>
```

Sau đó mở **một terminal thứ hai** và kiểm tra:

```bash
ssh -i <private-key-path> <app-user>@<server-ip>
sudo -v
```

Chỉ tiếp tục hardening SSH khi phiên này thành công.

## 13. Hardening SSH

Các thiết lập thường dùng:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Thao tác an toàn:

1. Xác định file cấu hình được hệ điều hành sử dụng: `/etc/ssh/sshd_config` hoặc file trong `sshd_config.d`.
2. Sao lưu file trước khi sửa.
3. Không đóng phiên SSH hiện tại.
4. Kiểm tra cú pháp:

```bash
sudo sshd -t
```

5. Reload dịch vụ phù hợp:

```bash
sudo systemctl reload ssh || sudo systemctl reload sshd
```

6. Kiểm tra lại bằng terminal mới.

## 14. Cấu hình firewall hai lớp

Phải cấu hình cả:

- Cloud firewall/Security Group của nhà cung cấp.
- Host firewall trên máy chủ.

Với UFW, cách độc lập với web server profile:

```bash
sudo ufw allow <ssh-port>/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Trên Ubuntu, Nginx thường đăng ký các application profile. Có thể kiểm tra và dùng `Nginx Full` như một cách tương đương để mở `80/443`:

```bash
sudo ufw app list
sudo ufw allow 'Nginx Full'
sudo ufw status verbose
```

Chọn **một** trong hai cách trên, không tạo rule trùng lặp không cần thiết. Khi sửa/xóa rule, kiểm tra bằng `sudo ufw status numbered` trước; không xóa mù theo tên. Sau khi bật, xác minh UFW vẫn được quản lý khi boot:

```bash
systemctl is-enabled ufw || true
systemctl is-active ufw || true
```

Trước khi bật UFW, bắt buộc phải có rule SSH đúng. Nếu dùng SSH port khác `22`, không dùng profile `OpenSSH` một cách máy móc.

## 15. Chuẩn hóa thư mục ứng dụng

```text
/srv/<app-name>/
├── current -> releases/<release-id>
├── releases/
│   ├── <release-id-1>/
│   └── <release-id-2>/
└── shared/
    ├── .env
    ├── uploads/
    └── logs/
```

Tạo thư mục:

```bash
sudo mkdir -p /srv/<app-name>/{releases,shared,shared/uploads,shared/logs}
sudo chown -R <app-user>:<app-user> /srv/<app-name>
sudo chmod 750 /srv/<app-name>
```

Mô hình release directory giúp rollback nhanh và tránh build trực tiếp đè lên bản đang chạy.

---

# PHẦN C - RUNTIME, SOURCE CODE VÀ SECRETS

## 16. Cài runtime

### 16.1 Quy tắc chung

- Dùng version được khai báo trong repository.
- Không tự động dùng bản "mới nhất" nếu chưa xác minh tương thích.
- Với Node.js, đọc `.nvmrc`, `.node-version` hoặc `package.json#engines`.
- Với Java, kiểm tra JDK target.
- Với Python, dùng virtual environment hoặc container.
- Với native dependency, kiểm tra architecture `amd64/arm64`.

### 16.2 Node.js native

Có thể dùng NVM, package repository chính thức hoặc runtime manager đã được dự án chuẩn hóa. Nếu cài NVM trong phiên hiện tại, reload shell profile hoặc đăng nhập lại trước khi gọi `nvm`:

```bash
source ~/.bashrc 2>/dev/null || true
command -v nvm
```

Cài và chọn đúng version đã phát hiện từ repository, không tự ý dùng bản mới nhất:

```bash
nvm install <runtime-version>
nvm use <runtime-version>
nvm alias default <runtime-version>
```

Sau khi cài:

```bash
node --version
<package-manager> --version
```

Không hard-code một phiên bản NVM installer cũ vào SOP. Khi cần cài mới, agent phải lấy lệnh cài runtime manager từ tài liệu chính thức tương ứng với thời điểm triển khai.

### 16.3 Docker Compose

Nếu chọn Docker:

- Cài Docker Engine và Compose plugin bằng phương pháp chính thức cho hệ điều hành.
- Thêm user deploy vào group Docker chỉ khi chấp nhận rằng quyền Docker gần tương đương root.
- Kiểm tra:

```bash
docker version
docker compose version
```

## 17. Cấp quyền đọc repository private

Ưu tiên theo thứ tự:

1. CI build artifact/container image và server chỉ pull artifact.
2. Deploy key chỉ đọc cho đúng repository.
3. Machine user/service account với quyền tối thiểu.

Không đặt personal access token trực tiếp trong remote URL, shell history hoặc repository.

Ví dụ tạo deploy key trên server:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<app-name>_deploy -C "<app-name>-production-deploy"
cat ~/.ssh/<app-name>_deploy.pub
```

Cấu hình host alias nếu cần:

```sshconfig
Host github-<app-name>
  HostName github.com
  User git
  IdentityFile ~/.ssh/<app-name>_deploy
  IdentitiesOnly yes
```

Xác minh key/host alias trước khi clone. Lệnh test tùy Git provider; ví dụ với GitHub:

```bash
ssh -T git@github-<app-name> || true
git ls-remote <repository-url> HEAD
```

`ssh -T` có thể trả exit code khác `0` dù xác thực thành công vì Git provider không cung cấp shell; agent phải đọc output thay vì chỉ nhìn exit code. `git ls-remote` phải đọc được repository/HEAD theo quyền dự kiến.

## 18. Quản lý secrets

Secrets có thể đến từ:

- Secret manager của cloud.
- Vault/secret store của tổ chức.
- File environment được truyền qua kênh bảo mật.
- CI/CD secret inject vào server.

Quy tắc file env:

```bash
sudo install -d -m 750 -o <app-user> -g <app-user> /etc/<app-name>
sudo install -m 640 -o <app-user> -g <app-user> \
  <secure-local-env-file> \
  /etc/<app-name>/<app-name>.env
```

Không:

- Commit `.env`.
- In toàn bộ `.env` vào log.
- Gửi secret trong prompt không được bảo vệ.
- Dùng cùng secret cho development và production.

Agent chỉ được log **tên biến**, không log giá trị.

---

# PHẦN D - TRIỂN KHAI ỨNG DỤNG

## 19. Tạo release mới

```bash
export APP_NAME=<app-name>
export APP_ROOT=/srv/$APP_NAME
export RELEASE_ID=$(date -u +%Y%m%dT%H%M%SZ)-<short-sha>
export RELEASE_DIR=$APP_ROOT/releases/$RELEASE_ID

mkdir -p "$RELEASE_DIR"
```

### 19.1 Phương án Git clone

```bash
git clone --branch <branch> --single-branch <repository-url> "$RELEASE_DIR"
cd "$RELEASE_DIR"
git checkout <commit-sha>
git rev-parse HEAD
```

### 19.2 Phương án artifact

CI build artifact hoặc image trước, sau đó server chỉ tải artifact đã được định danh bằng version/SHA. Đây là phương án dễ tái lập hơn `git pull` trực tiếp trên production.

## 20. Liên kết dữ liệu dùng chung

Ví dụ:

```bash
ln -sfn /etc/<app-name>/<app-name>.env "$RELEASE_DIR/.env"
ln -sfn "$APP_ROOT/shared/uploads" "$RELEASE_DIR/uploads"
```

Chỉ liên kết đường dẫn thực sự được ứng dụng sử dụng. Không ghi đè thư mục repository nếu nó chứa source quan trọng.

## 21. Deploy native process

### 21.1 Cài dependency bằng lockfile

Chọn đúng một lệnh:

```bash
npm ci
pnpm install --frozen-lockfile
yarn install --immutable
bun install --frozen-lockfile
```

Sau đó:

```bash
<test-command-if-required>
<build-command>
```

Ứng dụng phải bind vào:

```text
HOST=127.0.0.1
PORT=<app-port>
NODE_ENV=production
```

### 21.2 Kiểm tra chạy foreground

```bash
<start-command>
```

Từ một terminal khác:

```bash
curl --fail --silent --show-error \
  http://127.0.0.1:<app-port><health-path>
```

Chỉ khi chạy foreground thành công mới chuyển sang process manager.

### 21.3 PM2 cho Node.js

Kiểm tra PM2 trước khi sử dụng:

```bash
command -v pm2 >/dev/null 2>&1 || npm install --global pm2
pm2 --version
```

PM2 phải được cài dưới đúng user chạy ứng dụng. Không dùng `sudo npm install -g pm2` khi Node.js được quản lý bằng NVM của user, vì có thể làm sai owner hoặc dùng nhầm runtime. Nếu repository đã pin PM2 như dependency, ưu tiên chạy qua package manager của dự án thay vì cài global.

Khuyến nghị lưu cấu hình trong repository hoặc deployment repo:

```javascript
// ecosystem.config.cjs
module.exports = {
  apps: [
    {
      name: '<app-name>',
      cwd: '/srv/<app-name>/current',
      script: '<package-manager>',
      args: '<start-args>',
      env: {
        NODE_ENV: 'production',
        HOST: '127.0.0.1',
        PORT: '<app-port>'
      },
      time: true,
      autorestart: true,
      max_memory_restart: '<memory-limit>'
    }
  ]
};
```

Khởi động hoặc reload:

```bash
pm2 startOrReload ecosystem.config.cjs --env production
pm2 save
pm2 status
```

Thiết lập startup chỉ một lần theo output do PM2 tạo:

```bash
pm2 startup
# Chạy đúng lệnh sudo mà PM2 in ra
pm2 save
```

Xác minh systemd unit do PM2 tạo cho đúng user:

```bash
systemctl status pm2-<app-user> --no-pager
systemctl is-enabled pm2-<app-user>
```

Không coi `pm2 save` là đủ nếu startup unit chưa được enable. Reboot test ở phần validation phải xác nhận process được restore.

### 21.4 systemd cho service native

Ví dụ khung service:

```ini
[Unit]
Description=<app-name>
After=network.target

[Service]
Type=simple
User=<app-user>
Group=<app-user>
WorkingDirectory=/srv/<app-name>/current
EnvironmentFile=/etc/<app-name>/<app-name>.env
ExecStart=<absolute-start-command>
Restart=always
RestartSec=5
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

Sau khi tạo `/etc/systemd/system/<app-name>.service`:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now <app-name>
sudo systemctl status <app-name> --no-pager
```

## 22. Deploy bằng Docker Compose

Yêu cầu tối thiểu:

- Image/tag gắn với commit SHA hoặc release version.
- Port chỉ bind localhost.
- Có healthcheck.
- Secrets không bake vào image.
- Volume persist được khai báo rõ.

Ví dụ:

```yaml
services:
  app:
    image: <registry>/<app-name>:<commit-sha>
    restart: unless-stopped
    env_file:
      - /etc/<app-name>/<app-name>.env
    ports:
      - "127.0.0.1:<app-port>:<container-port>"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1:<container-port><health-path>"]
      interval: 30s
      timeout: 5s
      retries: 3
```

Deploy:

```bash
docker compose pull
docker compose up -d --remove-orphans
docker compose ps
docker compose logs --tail=200 app
```

Nếu build trên server:

```bash
docker compose build --pull
docker compose up -d --remove-orphans
```

Build trên server cần đủ RAM/disk và thường kém tái lập hơn build image trong CI.

## 23. Deploy static website

Build artifact trước, sau đó copy vào release directory:

```bash
sudo mkdir -p /var/www/<app-name>/releases/<release-id>
sudo rsync -a --delete <build-output>/ \
  /var/www/<app-name>/releases/<release-id>/
sudo ln -sfn \
  /var/www/<app-name>/releases/<release-id> \
  /var/www/<app-name>/current
```

Nginx sẽ phục vụ trực tiếp từ `/var/www/<app-name>/current`.

## 24. Migration database

Migration là thao tác riêng, không được coi như một command build thông thường.

Agent phải:

1. Xác định migration có backward-compatible không.
2. Backup database hoặc xác nhận cơ chế point-in-time recovery.
3. Ghi lại version schema hiện tại.
4. Chạy migration bằng tài khoản có quyền tối thiểu.
5. Không tự động rollback migration phá hủy dữ liệu.
6. Với zero-downtime, ưu tiên chiến lược expand-and-contract.

```bash
<migration-command>
```

Nếu migration thất bại, dừng deployment và làm theo runbook dữ liệu.

## 25. Kích hoạt release

Sau khi build và health check nội bộ đạt:

```bash
ln -sfn "$RELEASE_DIR" "$APP_ROOT/current"
```

Sau đó reload process manager:

```bash
# PM2
pm2 startOrReload "$APP_ROOT/current/ecosystem.config.cjs" --env production

# systemd
sudo systemctl restart <app-name>

# Docker Compose
cd "$APP_ROOT/current" && docker compose up -d --remove-orphans
```

---

# PHẦN E - DNS, NGINX VÀ HTTPS

## 26. Trỏ DNS

Tối thiểu:

| Host | Type | Value |
|---|---|---|
| `@` hoặc subdomain | `A` | Public IPv4 cố định |
| `www` | `CNAME` | Domain chính |

Chỉ tạo `AAAA` khi server đã cấu hình IPv6 và firewall IPv6 đúng.

Kiểm tra:

```bash
dig +short <domain> A
dig +short <domain> AAAA
```

Điều kiện đạt:

- Domain phân giải về đúng server.
- Không tồn tại record cũ gây xung đột.
- Public IP sẽ không thay đổi ngoài ý muốn.

### 26.1 Domain gốc, `www` và subdomain

Ví dụ record phổ biến:

| Nhu cầu | Host | Type | Value |
|---|---|---|---|
| Domain gốc | `@` | `A` | Public IPv4 cố định |
| `www` theo domain gốc | `www` | `CNAME` | `<domain>` |
| Subdomain ứng dụng | `app` | `A` | Public IPv4 cố định |
| `www` của subdomain, chỉ khi thật sự cần | `www.app` | `CNAME` | `app.<domain>` |

Agent phải xác định một **canonical host**. Các alias còn lại phải redirect về canonical host thay vì phục vụ hai bản URL độc lập, nhằm tránh cookie/domain behavior không nhất quán và duplicate content.

Không coi DNS đã sẵn sàng chỉ vì record vừa được lưu trên dashboard. Phải kiểm tra bằng resolver độc lập và ghi lại kết quả `dig` trước khi chạy Certbot.

## 27. Cấu hình Nginx reverse proxy

Trước khi tạo virtual host, xác minh Nginx đã được cài và chạy:

```bash
sudo systemctl enable --now nginx
systemctl is-active nginx
curl -I http://127.0.0.1
```

Trên một server hoàn toàn mới, response có thể là trang mặc định `Welcome to nginx!`. Đây chỉ là kiểm tra web server bootstrap, không phải bằng chứng ứng dụng đã deploy thành công.

Tạo `/etc/nginx/sites-available/<app-name>`:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name <domain> <optional-aliases>;

    location / {
        proxy_pass http://127.0.0.1:<app-port>;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
```

Kích hoạt:

```bash
sudo ln -sfn \
  /etc/nginx/sites-available/<app-name> \
  /etc/nginx/sites-enabled/<app-name>

sudo nginx -t
sudo systemctl reload nginx
```

Không sửa `nginx.conf` toàn cục nếu một file site-level đã đủ đáp ứng yêu cầu.

### 27.1 Nginx cho static SPA

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name <domain>;

    root /var/www/<app-name>/current;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Nếu không phải SPA, không tự động fallback mọi route về `index.html`.

### 27.2 Upload file lớn hoặc request dài

Chỉ thêm khi ứng dụng cần:

```nginx
client_max_body_size <size>;
proxy_read_timeout <seconds>;
```

Không tăng giới hạn vô điều kiện.

### 27.3 Xử lý default site và xung đột virtual host

Trước khi xóa default site, agent phải kiểm tra server có đang phục vụ ứng dụng khác không:

```bash
ls -la /etc/nginx/sites-enabled/
sudo nginx -T | grep -nE 'server_name|listen '
```

Nếu đây là server mới và default site gây bắt nhầm request, có thể disable nó:

```bash
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

Không xóa file cấu hình của site khác. Với server chạy nhiều ứng dụng, mỗi domain phải có `server_name` rõ ràng và port nội bộ riêng.

### 27.4 Test virtual host trước khi DNS hoàn tất

Có thể kiểm tra Nginx route đúng site bằng Host header:

```bash
curl -I -H 'Host: <domain>' http://127.0.0.1
```

Kết quả phải đến đúng virtual host, không rơi vào default site hoặc site của ứng dụng khác.

### 27.5 Xử lý lỗi `server_names_hash_bucket_size`

Tài liệu nguồn đề xuất luôn mở `server_names_hash_bucket_size 64;`, nhưng SOP chuẩn **không sửa global config vô điều kiện**. Chỉ thực hiện khi `sudo nginx -t` báo lỗi liên quan đến `server_names_hash_bucket_size` hoặc `server_names_hash_max_size`.

Sao lưu và sửa trong block `http` của `/etc/nginx/nginx.conf`:

```nginx
http {
    server_names_hash_bucket_size 64;
    # ...
}
```

Sau đó bắt buộc kiểm tra và chỉ reload khi hợp lệ:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Nếu `64` vẫn không đủ, agent phải dựa trên lỗi thực tế và tài liệu Nginx để chọn giá trị tiếp theo; không tăng tùy tiện trên mọi server.

## 28. Kiểm tra HTTP trước TLS

```bash
sudo nginx -t
systemctl is-active nginx
curl -I http://127.0.0.1:<app-port><health-path>
curl -I http://<domain>
```

Nếu Nginx trả `502 Bad Gateway`, không tiếp tục xin chứng chỉ trước khi xử lý upstream.

## 29. Cài HTTPS/TLS

Dùng Certbot/ACME client theo phương thức chính thức của hệ điều hành tại thời điểm triển khai. Agent phải ghi lại phương thức cài (`snap`, package hệ điều hành, container hoặc ACME client khác) và không trộn hai bản Certbot trên cùng `PATH`.

### 29.1 Ví dụ Certbot qua Snap trên Ubuntu/Debian

Đây là luồng tương ứng với tài liệu PDF và hướng dẫn Certbot chính thức hiện hành cho lựa chọn Nginx trên Linux dùng Snap. Chỉ dùng khi hệ điều hành hỗ trợ Snap và sau khi đối chiếu hướng dẫn chính thức tại thời điểm deploy:

```bash
sudo apt-get update
sudo apt-get install -y snapd

# Chỉ gỡ package Certbot cũ khi chủ đích chuyển sang bản Snap.
sudo apt-get remove -y certbot || true

sudo snap install --classic certbot

# Nếu đường dẫn chưa tồn tại; nếu đã tồn tại phải inspect trước, không ghi đè mù.
sudo ln -s /snap/bin/certbot /usr/local/bin/certbot
certbot --version
```

Không gỡ Certbot đang vận hành trên production nếu chưa kiểm tra certificate, renewal unit và rollback. Nếu provider/image không dùng Snap, agent phải dùng installation path chính thức phù hợp thay vì ép cài Snap.

### 29.2 Cấp và cài chứng chỉ cho Nginx

```bash
sudo certbot --nginx \
  -d <domain> \
  -d <optional-alias>
```

Agent phải:

- Xác nhận DNS đúng trước khi chạy.
- Dùng email vận hành có người theo dõi.
- Chấp nhận điều khoản theo chính sách tổ chức.
- Chọn redirect HTTP sang HTTPS.
- Không bật HSTS ngay trong lần đầu nếu chưa xác nhận HTTPS ổn định và toàn bộ subdomain phù hợp.

Kiểm tra gia hạn:

```bash
sudo certbot renew --dry-run
```

Kiểm tra timer/service:

```bash
systemctl list-timers | grep -i certbot || true
systemctl status snap.certbot.renew.timer --no-pager 2>/dev/null || true
```

Agent không hard-code nhận định timer chạy đúng hai lần mỗi ngày; cadence phụ thuộc gói cài đặt. Điều bắt buộc là có cơ chế renewal tự động, `renew --dry-run` đạt, email vận hành hợp lệ và một kênh cảnh báo khi renewal thất bại hoặc chứng chỉ sắp hết hạn.

## 30. Kiểm tra HTTPS

```bash
curl -I http://<domain>
curl -I https://<domain>
curl --fail --silent --show-error https://<domain><health-path>
```

Điều kiện đạt:

- HTTP chuyển hướng sang HTTPS.
- HTTPS trả status mong đợi.
- Chứng chỉ đúng domain và chưa hết hạn.
- Nginx proxy tới đúng ứng dụng.
- Không có mixed-content nghiêm trọng trong smoke test trình duyệt.

### 30.1 Kích hoạt HTTP/2 trên Nginx

HTTP/2 được bật tại lớp Nginx/TLS, không phải trong ứng dụng phía sau reverse proxy. Chỉ thực hiện bước này sau khi HTTPS đã hoạt động ổn định.

#### 30.1.1 Kiểm tra điều kiện hỗ trợ

```bash
nginx -v
nginx -V 2>&1 | grep -- '--with-http_v2_module'
openssl version
```

Điều kiện:

- Nginx có module HTTP/2.
- HTTPS đã được cấu hình cho đúng virtual host.
- TLS stack hỗ trợ ALPN.
- Agent xác định request public có terminate TLS tại Nginx, CDN hay load balancer. Nếu TLS terminate ở CDN/load balancer, HTTP/2 phía người dùng phải được kiểm tra tại lớp đó; cấu hình origin Nginx không đủ để kết luận.

#### 30.1.2 Cú pháp cho Nginx hiện đại

Với Nginx hỗ trợ directive `http2` độc lập, dùng:

```nginx
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    http2 on;

    server_name <domain> <optional-aliases>;

    ssl_certificate <certificate-path>;
    ssl_certificate_key <private-key-path>;

    # Các location/reverse proxy hiện có giữ nguyên.
}
```

#### 30.1.3 Cú pháp tương thích Nginx cũ

Nếu phiên bản Nginx chưa hỗ trợ `http2 on;`, dùng cú pháp legacy:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name <domain> <optional-aliases>;

    # Các cấu hình TLS và reverse proxy hiện có giữ nguyên.
}
```

Agent không được thêm đồng thời hai cú pháp. Phải chọn cú pháp theo phiên bản Nginx thực tế. Không thêm các directive `http2_push` hoặc `http2_push_preload`; server push đã lỗi thời và không phải điều kiện để sử dụng HTTP/2.

Sau khi sửa:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Nếu `nginx -t` thất bại, không reload; khôi phục file cấu hình trước đó rồi kiểm tra lại.

#### 30.1.4 Xác minh HTTP/2 thực sự được negotiate

Kiểm tra curl có hỗ trợ HTTP/2:

```bash
curl -V
```

Xác minh protocol:

```bash
curl --http2 -I https://<domain>
curl --silent --show-error --output /dev/null \
  --write-out '%{http_version}\n' \
  https://<domain><health-path>
```

Kỳ vọng header status bắt đầu bằng `HTTP/2` hoặc giá trị protocol là `2`/`2.0`, tùy phiên bản curl.

Kiểm tra ALPN khi cần:

```bash
openssl s_client \
  -connect <domain>:443 \
  -servername <domain> \
  -alpn h2 </dev/null 2>/dev/null \
  | grep -i 'ALPN protocol'
```

Kỳ vọng negotiated protocol là `h2`.

Sau khi bật HTTP/2, vẫn phải xác minh client HTTP/1.1 hoạt động để bảo đảm tương thích:

```bash
curl --http1.1 -I https://<domain>
```

> HTTP/2 không đồng nghĩa với HTTP/3. HTTP/3/QUIC là một hạng mục riêng, yêu cầu UDP/443, module và chính sách firewall khác; agent không tự bật ngoài scope.

---

# PHẦN F - VALIDATION VÀ SECURITY REVIEW

## 31. Kiểm tra process và port

```bash
sudo ss -lntp
```

Kỳ vọng:

- Nginx lắng nghe `0.0.0.0:80` và `0.0.0.0:443` hoặc tương đương IPv6.
- Nếu HTTP/2 nằm trong scope, public endpoint negotiate được `h2`; nếu có CDN/load balancer phải ghi rõ lớp terminate protocol.
- Ứng dụng chỉ lắng nghe `127.0.0.1:<app-port>` hoặc private interface.
- Database/cache nội bộ không mở public ngoài chủ đích.

Process:

```bash
# PM2
pm2 status
pm2 logs <app-name> --lines 100 --nostream

# systemd
systemctl status <app-name> --no-pager
journalctl -u <app-name> -n 100 --no-pager

# Docker
docker compose ps
docker compose logs --tail=100 app
```


## 32. Smoke test chức năng

Agent phải test ít nhất:

- Trang chủ hoặc endpoint gốc.
- Health endpoint.
- Một luồng đọc dữ liệu quan trọng.
- Đăng nhập nếu có tài khoản test an toàn.
- Upload/download nếu feature này nằm trong scope.
- API gọi từ frontend không bị CORS/cookie/domain lỗi.
- Static asset, image và font tải được.
- Redirect `www`/non-`www` đúng chính sách.

Không dùng dữ liệu production nhạy cảm để smoke test nếu không cần thiết.

## 33. Reboot test

Chỉ reboot nếu được phép và có cửa sổ phù hợp:

```bash
sudo reboot
```

Sau khi server trở lại:

- SSH đăng nhập được.
- Firewall vẫn đúng.
- Nginx active.
- PM2/systemd/Docker tự khởi động.
- Ứng dụng health check thành công.
- HTTPS vẫn hoạt động.

Nếu không được phép reboot, phải ghi rõ đây là validation chưa thực hiện.

## 34. Security acceptance

- Root SSH login đã tắt hoặc được kiểm soát theo policy.
- Password SSH login đã tắt nếu key login hoạt động.
- SSH chỉ cho phép từ nguồn tin cậy nếu khả thi.
- Chỉ `80/443` public cho web.
- App port không public.
- Secrets có permission tối thiểu.
- Không có secret trong Git, process command hoặc log.
- OS và package quan trọng đã được cập nhật.
- Backup/restore owner đã được xác định.

---

# PHẦN G - QUY TRÌNH REDEPLOY

## 35. Pre-deploy cho mỗi lần cập nhật

Agent phải ghi nhận:

```text
Current release/image:
Current commit SHA:
Target commit SHA:
Database schema version:
Environment checksum hoặc version:
Available disk/RAM:
Rollback target:
```

Kiểm tra:

```bash
df -h
free -h
git status --short
```

Production working tree không được chứa thay đổi tay không rõ nguồn gốc.

## 36. Quy trình cập nhật an toàn

```text
1. Lock deployment để tránh hai deploy chạy đồng thời.
2. Tạo release mới, không ghi đè release hiện tại.
3. Cài dependency bằng lockfile.
4. Chạy test/build.
5. Chạy migration theo policy.
6. Chạy app hoặc container mới và health check.
7. Chuyển `current` sang release mới.
8. Reload/restart process theo cơ chế ít downtime nhất.
9. Smoke test qua HTTPS.
10. Theo dõi log trong khoảng thời gian xác định.
11. Đánh dấu release thành công hoặc rollback.
12. Xóa release cũ vượt quá retention sau khi ổn định.
```

### 36.1 Deployment lock

Có thể dùng `flock` trong script deploy:

```bash
flock -n /var/lock/<app-name>-deploy.lock \
  /usr/local/bin/<app-name>-deploy
```

## 37. Script deploy khuyến nghị

Repository hoặc infra repo nên có:

```text
scripts/
├── deploy.sh
├── rollback.sh
├── healthcheck.sh
└── backup.sh
```

`deploy.sh` phải dùng chế độ nghiêm ngặt:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Script phải:

- Validate biến đầu vào.
- Ghi log thời gian và release ID.
- Trap lỗi và in bước thất bại.
- Không in secret.
- Chỉ cập nhật symlink khi build/health đạt.
- Trả exit code khác `0` khi deploy thất bại.

## 38. Chiến lược giảm downtime

Theo thứ tự tăng độ phức tạp:

1. Restart process ngắn.
2. PM2 reload/cluster mode.
3. Docker recreate service.
4. Blue-green trên hai port nội bộ và đổi Nginx upstream.
5. Load balancer với nhiều instance.

Không xây blue-green hoặc load balancer nếu scope chỉ yêu cầu một VPS tối giản.

---

# PHẦN H - ROLLBACK

## 39. Điều kiện kích hoạt rollback

Rollback khi một trong các điều kiện sau xảy ra:

- Health check thất bại.
- Tỷ lệ lỗi tăng rõ rệt.
- Nginx trả `502/504` kéo dài.
- Chức năng chính thất bại trong smoke test.
- Memory/CPU tăng bất thường do release mới.
- Migration hoặc schema không tương thích.
- TLS/DNS/config bị hỏng sau thay đổi.

## 40. Rollback release directory

```bash
readlink -f /srv/<app-name>/current
ls -1dt /srv/<app-name>/releases/*

ln -sfn \
  /srv/<app-name>/releases/<previous-release> \
  /srv/<app-name>/current
```

Sau đó reload process và kiểm tra:

```bash
<reload-command>
curl --fail https://<domain><health-path>
```

## 41. Rollback Docker

```bash
# Đổi image tag/SHA về bản trước trong compose/env
docker compose pull
docker compose up -d --remove-orphans
```


## 42. Rollback database

- Không tự động chạy `down migration` nếu có nguy cơ mất dữ liệu.
- Ưu tiên rollback application trước nếu schema mới backward-compatible.
- Nếu bắt buộc restore database, cần owner/phê duyệt và runbook riêng.
- Ghi rõ RPO/RTO và phạm vi dữ liệu có thể mất.

---

# PHẦN I - BACKUP, MONITORING VÀ BẢO TRÌ

## 43. Backup tối thiểu

Phân biệt:

- Snapshot máy chủ/disk.
- Backup database.
- Backup upload/user-generated content.
- Backup cấu hình Nginx, systemd, Compose và env đã mã hóa.
- Backup DNS/IaC configuration.

Snapshot server không thay thế backup database nhất quán.

Mỗi backup policy phải có:

```text
What: dữ liệu nào
Where: lưu ở đâu
Frequency: tần suất
Retention: giữ bao lâu
Encryption: mã hóa thế nào
Restore owner: ai chịu trách nhiệm
Last restore test: lần test phục hồi gần nhất
```

## 44. Logging

Các nguồn log chính:

```bash
# Nginx
sudo tail -n 200 /var/log/nginx/access.log
sudo tail -n 200 /var/log/nginx/error.log

# PM2
pm2 logs <app-name>

# systemd
journalctl -u <app-name> -f

# Docker
docker compose logs -f --tail=200
```


Cần log rotation để tránh đầy disk.

## 45. Monitoring tối thiểu

Theo dõi:

- HTTP uptime và response time.
- CPU, RAM, swap, disk và inode.
- Process/container restart count.
- Nginx `5xx`.
- Certificate expiration.
- Database connection/error rate.
- Backup success/failure.

## 46. Bảo trì định kỳ

- Cập nhật security patch theo lịch.
- Kiểm tra disk/log.
- Kiểm tra `certbot renew --dry-run` sau thay đổi TLS.
- Xóa release/image cũ theo retention.
- Rotate deploy key và secrets.
- Test restore định kỳ.
- Review firewall và user SSH.
- Review chi phí cloud và tài nguyên không dùng.

---

# PHẦN J - CI/CD

## 47. Luồng CI/CD đề xuất

```text
Push/Merge vào branch production
        |
        v
CI: install -> test -> lint -> build
        |
        v
Tạo artifact hoặc container image theo commit SHA
        |
        v
Deploy job có concurrency lock
        |
        v
Server nhận artifact/image
        |
        v
Health check -> activate release
        |
        +--> success: ghi deployment record
        |
        +--> failure: rollback + thông báo
```

## 48. Nguyên tắc CI/CD

- Chỉ deploy commit đã vượt quality gate.
- Dùng environment protection/approval nếu production quan trọng.
- Không dùng SSH private key cá nhân dùng chung lâu dài.
- Secret CI có quyền tối thiểu.
- Pin server host key thay vì tắt host key checking.
- Không cho hai workflow deploy cùng lúc.
- Gắn artifact/image với commit SHA.
- Không build lại khác nhau giữa CI và server nếu có thể tránh.
- Giữ log deploy nhưng redact secrets.

## 49. Phương án CI/CD tối giản qua SSH

CI có thể:

1. Build/test.
2. `rsync` artifact hoặc gọi deploy script trên server.
3. Server tự tạo release và activate.
4. CI gọi health endpoint.
5. Nếu lỗi, gọi rollback script hoặc để server tự rollback.

Không đặt toàn bộ chuỗi deploy khó kiểm soát trong một dòng `ssh "cd ... && git pull && ..."` đối với production quan trọng. Nên đóng gói thành script version-controlled và idempotent.

---

# PHẦN K - TROUBLESHOOTING

## 50. Nginx trả 502 Bad Gateway

Kiểm tra theo thứ tự:

```bash
curl -v http://127.0.0.1:<app-port><health-path>
sudo ss -lntp | grep <app-port>
sudo nginx -t
sudo tail -n 100 /var/log/nginx/error.log
```

Nguyên nhân thường gặp:

- App chưa chạy hoặc crash loop.
- Sai port.
- App bind `localhost` khác network namespace trong Docker.
- Nginx proxy sai hostname/container.
- Firewall nội bộ hoặc permission.

## 51. Domain chưa vào đúng server

```bash
dig +short <domain> A
dig +trace <domain>
```

Kiểm tra record cũ, proxy CDN, TTL và public IP.

## 52. Certbot thất bại

Kiểm tra:

- DNS đã đúng chưa.
- Port `80` public chưa.
- Nginx config hợp lệ chưa.
- Domain có đi qua CDN/proxy gây challenge lỗi không.
- Rate limit do thử quá nhiều lần không.

Không lặp command xin chứng chỉ liên tục khi chưa sửa nguyên nhân.

### 52.1 HTTPS hoạt động nhưng không negotiate HTTP/2

Kiểm tra theo thứ tự:

```bash
nginx -v
nginx -V 2>&1 | grep -- '--with-http_v2_module'
sudo nginx -T | grep -nE 'listen 443|http2'
curl -V
curl --silent --output /dev/null --write-out '%{http_version}\n' https://<domain>
openssl s_client -connect <domain>:443 -servername <domain> -alpn h2 </dev/null 2>/dev/null \
  | grep -i 'ALPN protocol'
```

Nguyên nhân thường gặp:

- Directive HTTP/2 nằm sai `server` block.
- Nginx không có module HTTP/2.
- Đang dùng cú pháp không tương thích với phiên bản Nginx.
- TLS/ALPN không được negotiate.
- `curl` trên máy kiểm tra không được build với HTTP/2.
- CDN hoặc load balancer terminate TLS và chưa bật HTTP/2 tại edge.
- DNS đang trỏ sang server/edge khác với nơi vừa sửa cấu hình.

Không kết luận HTTP/2 thất bại chỉ từ một bản curl không hỗ trợ HTTP/2; phải xác minh thêm bằng ALPN hoặc browser DevTools.

## 53. App bị OOM hoặc build bị kill

```bash
free -h
dmesg -T | grep -i -E 'killed process|out of memory' || true
```

Hướng xử lý:

- Build trong CI thay vì trên VPS.
- Tăng RAM/instance size.
- Thêm swap có kiểm soát cho server nhỏ.
- Giới hạn memory process/container.
- Kiểm tra memory leak.

## 54. Port đã được sử dụng

```bash
sudo ss -lntp | grep :<app-port>
```

Không kill process trước khi xác định nó thuộc service nào.

## 55. Permission denied

Kiểm tra owner/permission tại:

- App directory.
- `.ssh` và `authorized_keys`.
- Env file.
- Upload directory.
- Unix socket nếu dùng.

Không dùng `chmod 777` để chữa lỗi production.

---

# PHẦN L - HỢP ĐỒNG ĐẦU RA CỦA AGENT

## 56. Báo cáo trước khi thực thi

Agent phải xuất:

```markdown
## Deployment plan

- Target provider/server:
- Repository/commit:
- Deploy mode:
- Domain:
- Internal port:
- Required firewall changes:
- Required DNS changes:
- Secrets source:
- Migration plan:
- Rollback plan:
- Expected downtime:
- Risks/assumptions:
- Approval-required actions:
```

## 57. Báo cáo sau khi thực thi

```markdown
## Deployment result

- Status: SUCCESS | FAILED | ROLLED_BACK | PARTIAL
- Server:
- Environment:
- Release ID:
- Commit SHA:
- Public URL:
- Health endpoint:
- Process manager:
- App process status:
- Nginx status:
- TLS status:
- Public ports:
- Database migration:
- Smoke tests:
- Reboot test:
- Rollback target:
- Evidence/log locations:
- Remaining risks:
- Manual follow-up:
```

## 58. Evidence bắt buộc

- `git rev-parse HEAD` hoặc image digest.
- `systemctl`/PM2/Docker status.
- `nginx -t`.
- `ufw status` và/hoặc cloud firewall summary.
- `curl` localhost health.
- `curl` HTTPS public health.
- Kết quả HTTP protocol negotiation (`curl --write-out '%{http_version}'` hoặc ALPN), nếu HTTP/2 nằm trong scope.
- TLS renewal dry run hoặc lý do chưa chạy.
- Release directory/image version trước và sau deploy.
- Kết quả rollback readiness.

Agent phải redact IP nội bộ nhạy cảm, token, cookie, password và secret values theo policy của tổ chức.

---

# PHẦN M - DEFINITION OF DONE

## 59. Checklist nghiệm thu

### Repository

- [ ] Commit SHA được cố định.
- [ ] Dependency cài bằng lockfile.
- [ ] Test/lint/build cần thiết đã đạt.
- [ ] Không có secret trong source/log.

### Server

- [ ] Server dùng OS/runtime/architecture tương thích.
- [ ] Có user deploy không phải root.
- [ ] SSH key login hoạt động.
- [ ] SSH hardening không làm mất quyền truy cập.
- [ ] Cloud firewall và host firewall đúng scope.
- [ ] App port không public.

### Application

- [ ] App chạy bằng PM2/systemd/Docker và tự khởi động lại.
- [ ] Health check nội bộ thành công.
- [ ] Secrets có permission tối thiểu.
- [ ] Persistent data nằm ngoài release directory.

### Network

- [ ] DNS phân giải đúng.
- [ ] Nginx config qua `nginx -t`.
- [ ] HTTP redirect sang HTTPS.
- [ ] TLS hợp lệ đúng domain.
- [ ] HTTP/2 negotiate thành công khi được yêu cầu trong deployment manifest.
- [ ] Renewal dry run thành công.

### Operations

- [ ] Smoke test chức năng chính đạt.
- [ ] Rollback target tồn tại và đã được ghi nhận.
- [ ] Backup/migration policy được xác nhận.
- [ ] Log và monitoring có đường dẫn/owner rõ ràng.
- [ ] Deployment report và evidence đã bàn giao.

Chỉ được đánh dấu **SUCCESS** khi tất cả mục bắt buộc trong scope đạt hoặc được ghi rõ là ngoại lệ đã được phê duyệt.

---

# PHẦN N - QUICK RUNBOOK

## 60. Luồng rút gọn dành cho agent đã hiểu hệ thống

```text
1. Inspect repo và cố định commit SHA.
2. Chạy install/test/lint/build.
3. Kiểm tra server, IP, OS, architecture và firewall.
4. SSH bằng key, tạo deploy user và harden SSH an toàn.
5. Cài runtime/process manager/Nginx.
6. Tạo release directory và cấp secrets.
7. Cài dependency, build và chạy app trên localhost.
8. Health check nội bộ.
9. Trỏ DNS về IP cố định.
10. Cấu hình Nginx reverse proxy và chạy nginx -t.
11. Cấp TLS, redirect HTTPS và test renewal.
12. Bật và xác minh HTTP/2 nếu nằm trong scope.
13. Smoke test URL production.
14. Kiểm tra process, port, log và restart persistence.
15. Ghi release, evidence và rollback target.
16. Bàn giao deployment report.
```

---

## 61. Những hành vi agent tuyệt đối không được làm

- `chmod -R 777` để xử lý permission.
- Mở `0.0.0.0/0` cho SSH nếu có thể giới hạn nguồn.
- Mở public app port hoặc database port không cần thiết.
- Copy private SSH key sang server để "cho tiện".
- Commit `.env` hoặc hard-code secret vào Compose/Nginx/repository.
- Tắt firewall để xử lý lỗi tạm thời rồi quên bật lại.
- Dùng `git reset --hard`, xóa volume, xóa database hoặc recreate server khi chưa được phê duyệt.
- Xóa host key cũ mà chưa xác nhận server/IP thay đổi hợp lệ.
- Chạy migration phá hủy dữ liệu mà không backup/phê duyệt.
- Restart/reboot production ngoài scope hoặc ngoài cửa sổ cho phép.
- Báo thành công khi chỉ test localhost mà chưa test domain HTTPS.
- Xóa release cũ trước khi bản mới qua thời gian theo dõi.

---

## 62. Ghi chú nguồn và phạm vi chuẩn hóa

Tài liệu này được chuẩn hóa từ hướng dẫn triển khai Next.js/Node.js lên Ubuntu VPS theo luồng: tạo VPS, dùng SSH key, tạo user không phải root, cài runtime và Git, chạy ứng dụng bằng PM2, trỏ DNS, cấu hình UFW/Nginx reverse proxy, cấp HTTPS bằng Certbot và kiểm tra gia hạn chứng chỉ.

Bản SOP hiện tại đã mở rộng thêm:

- Tính độc lập với nhà cung cấp VPS/cloud.
- Quy trình tạo và quản lý SSH key trên máy quản trị.
- Docker, systemd, static hosting và nhiều runtime.
- Kích hoạt, kiểm tra và troubleshooting HTTP/2 theo phiên bản Nginx.
- Quality gate, evidence và stop condition cho agentic AI.
- Release directory, deployment lock, rollback và migration safety.
- Secrets, backup, monitoring, CI/CD và Definition of Done.

Các command cụ thể về cài runtime, Docker và Certbot cần được agent kiểm tra lại với tài liệu chính thức của hệ điều hành/nền tảng tại thời điểm thực thi; không sao chép mù version từ tài liệu cũ.

---

## 63. Ma trận audit độ phủ so với tài liệu PDF nguồn

Bảng này dùng để chứng minh mọi nội dung **có giá trị vận hành** trong PDF đã được giữ lại, chuẩn hóa hoặc thay thế bằng phương án an toàn hơn.

| Nội dung trong PDF nguồn | Vị trí trong SOP | Trạng thái/ghi chú |
|---|---|---|
| Ứng dụng phải chạy được và production build phải thành công trước deploy | Mục 6-8 | Giữ nguyên ý nghĩa, mở rộng thành preflight, test/lint/build và commit SHA |
| Chọn VPS, CPU, region, OS, kích thước, backup và SSH key khi tạo instance | Mục 9 | Chuẩn hóa độc lập provider; không cố định Vultr, gói 5 USD hay Ubuntu 22.04 x64 |
| Tạo SSH key Ed25519, phân biệt public/private key và cấu hình key tên riêng | Mục 9.2 | Giữ và harden thêm permission, passphrase/agent, `ssh -G` |
| Kiểm tra SSH client, đăng nhập bằng user/IP/key hoặc mật khẩu bootstrap | Mục 9.2, 10 | Đã bổ sung rõ `ssh -V`, key login và password fallback một lần |
| Xử lý host identification changed | Mục 10 | Giữ nhưng thêm điều kiện xác minh chống MITM trước khi xóa known host |
| Không dùng root hằng ngày; tạo user và thêm sudo | Mục 12-13 | Giữ và bổ sung kiểm tra terminal thứ hai trước khi harden SSH |
| Cài public key cho user bằng `ssh-copy-id` hoặc `authorized_keys` | Mục 12 | Đã giữ đủ cả hai cách và permission chuẩn |
| `apt update/upgrade`, cài Node qua NVM, reload shell, dùng đúng Node version | Mục 11, 16.2 | Giữ ý nghĩa; không pin NVM installer cũ, bổ sung `nvm install/use/alias` theo repo |
| Tạo SSH/deploy key trên server, thêm vào Git provider và clone repo | Mục 17, 19 | Giữ và giảm quyền xuống read-only; thêm `git ls-remote` kiểm tra |
| Cài dependency, build, chạy foreground để test | Mục 7, 21 | Giữ; dùng lockfile và localhost thay vì mở app port public |
| PM2 start/status/save/startup và kiểm tra sau reboot | Mục 21.3, 31, 33 | Giữ đủ; bổ sung systemd unit và reboot validation |
| Quy trình cập nhật code và restart PM2/GitHub Actions | Mục 35-38, 47-49 | Giữ mục tiêu nhưng thay `git pull`/one-liner bằng release, lock, health check và rollback |
| DNS domain gốc, `www`, subdomain, A/CNAME và TTL/propagation | Mục 26 | Giữ và chuẩn hóa canonical host, resolver check, IPv6 condition |
| Cài Nginx, UFW profiles, mở SSH/80/443 và kiểm tra web server | Mục 11, 14, 27 | Giữ; hỗ trợ cả port rule và `Nginx Full`, thêm bootstrap test |
| Nginx `sites-available`/`sites-enabled`, reverse proxy và WebSocket headers | Mục 27 | Giữ và mở rộng forwarded headers, timeout, static SPA, multi-site conflict |
| `server_names_hash_bucket_size 64` | Mục 27.5 | Không áp dụng mù; giữ dưới dạng xử lý có điều kiện theo lỗi `nginx -t` |
| `nginx -t` trước restart/reload | Mục 1, 27-30 | Trở thành nguyên tắc bắt buộc toàn tài liệu |
| Certbot qua Snap, `certbot --nginx`, email/terms, HTTPS redirect | Mục 29 | Giữ đầy đủ; installation path được kiểm tra theo OS/thời điểm |
| Renewal tự động và `certbot renew --dry-run` | Mục 29, 30, 45-46 | Giữ và thêm timer/status/evidence/monitoring certificate expiration |
| HTTP/2: điều kiện HTTPS, cấu hình Nginx, test và restart | Mục 30.1, 52.1 | Giữ cú pháp legacy và bổ sung cú pháp Nginx mới, ALPN/curl, CDN/LB awareness |
| Áp dụng quy trình cho framework/runtime khác ngoài Node.js | Mục 4, 16, 21-23 | Mở rộng chính thức cho Python, Java/Spring, Go/Gin, PHP, static và Docker |

### 63.1 Nội dung PDF chủ đích không đưa vào SOP

Các nội dung sau không phải bước kỹ thuật deploy nên được loại bỏ có chủ đích, không phải bỏ sót:

- Quảng cáo khóa học, referral/khuyến mãi Vultr, doanh thu cá nhân và lời giới thiệu tác giả.
- Yêu cầu tài khoản/thẻ thanh toán riêng của Vultr; SOP chỉ giữ yêu cầu quyền cấp phát và phê duyệt chi phí.
- Ảnh chụp giao diện dashboard theo phiên bản cũ; đã thay bằng khái niệm hạ tầng độc lập provider.
- Video nhúng, phần bình luận, nội dung marketing, bài viết liên quan và tài liệu tham khảo cuối trang.
- Các giá trị ví dụ có tính thời điểm như gói 5 USD, Ubuntu 22.04, Node.js 21 và NVM `v0.39.7`; agent phải lấy version từ project và nền tảng hiện tại.
- Khuyến nghị bỏ trống SSH passphrase; SOP thay bằng `ssh-agent`/credential store để an toàn hơn.
- Việc mở port ứng dụng `3000` ra Internet để test; SOP thay bằng bind localhost và `curl` nội bộ.
- Redeploy bằng một dòng `git pull && build && restart`; SOP thay bằng release bất biến, deployment lock, health check và rollback.
- Khẳng định DNS chắc chắn cập nhật sau một phút hoặc cache kéo dài cố định; SOP xác minh bằng resolver thực tế.
- Khẳng định UFW chỉ có hiệu lực trong phiên hiện tại; SOP xác minh service/rule thực tế của hệ điều hành.
- HTTP/2 server push như một lợi ích cần cấu hình; SOP không bật server push đã lỗi thời.

Nếu bổ sung hoặc xóa một phần có nguồn gốc từ PDF trong tương lai, agent cập nhật ma trận này cùng commit để audit có thể truy vết.
