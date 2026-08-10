# ChatGPT–Codex Collaboration Playbook

> Tài liệu portable để thiết lập nhanh cách làm việc giữa **ChatGPT Web**, **Codex CLI**, **GitHub** và người phụ trách repository trong bất kỳ team hoặc dự án nào.

## 1. Mục đích

Workflow này giải quyết một vấn đề đơn giản nhưng dễ gây lỗi:

- ChatGPT có khả năng phân tích, lập kế hoạch và review.
- Codex có khả năng đọc repository, sửa code, chạy kiểm tra và mở Pull Request.
- Hai AI không nên trao đổi bằng trí nhớ riêng hoặc các đoạn chat rời rạc.
- Team cần một nguồn sự thật chung, có lịch sử, có thể review và bàn giao.

Giải pháp là dùng **GitHub làm giao thức giao tiếp chung**.

```text
ChatGPT chuẩn bị Issue
        ↓
Codex đọc Issue và triển khai
        ↓
Codex mở Pull Request
        ↓
GitHub Actions kiểm tra độc lập
        ↓
ChatGPT review Issue + diff + CI
        ↓
Codex sửa feedback
        ↓
Con người phê duyệt và merge
```

## 2. Nguyên tắc cốt lõi

1. **GitHub Issue là task chính thức và ranh giới scope.**
2. **Pull Request là implementation report và nơi bàn giao.**
3. **PR comments/reviews là kênh feedback giữa ChatGPT và Codex.**
4. **Code, test và tài liệu đã commit quan trọng hơn trí nhớ của AI.**
5. **Codex không được tự mở rộng scope.**
6. **CI phải kiểm tra độc lập, không chỉ tin vào báo cáo của Codex.**
7. **Con người giữ quyền quyết định cuối cùng đối với merge và production.**
8. **Secret, credential và dữ liệu generated/local không được đưa vào Git.**

## 3. Vai trò và quyền hạn

### 3.1 ChatGPT Web

ChatGPT phù hợp với các công việc:

- đọc repository, Issue, Pull Request và tài liệu liên quan;
- phân tích yêu cầu và trạng thái hiện tại;
- xác định scope, out-of-scope và acceptance criteria;
- tạo hoặc hoàn thiện Issue cho Codex;
- review Pull Request dựa trên Issue, diff và CI;
- phân loại vấn đề thành blocker, should-fix và optional;
- ghi feedback có thể thực thi trực tiếp lên Pull Request;
- audit sau merge và đề xuất task tiếp theo.

ChatGPT **không phải merge authority** và không nên thay đổi scope chỉ bằng một đoạn chat riêng không được ghi lại trên GitHub.

### 3.2 Codex CLI

Codex phù hợp với các công việc:

- đọc Issue và tài liệu canonical;
- inspect repository và trạng thái Git hiện tại;
- lập implementation plan trong phạm vi được duyệt;
- tạo branch riêng;
- sửa code/tài liệu;
- chạy lint, test, build và các verification cần thiết;
- tự review toàn bộ diff;
- commit, push và mở Pull Request;
- phản hồi và sửa review comments;
- cập nhật evidence trong PR.

Codex được quyền **phân tích và đề xuất**, nhưng không được tự quyết định các thay đổi material về:

- scope;
- architecture;
- dependency;
- production impact;
- security boundary;
- dữ liệu hoặc hosted resources.

Khi cần vượt phạm vi, Codex phải dừng và yêu cầu cập nhật Issue hoặc spec trước.

### 3.3 GitHub Actions

GitHub Actions cung cấp bằng chứng độc lập cho Pull Request:

- cài dependency bằng lockfile;
- lint;
- test;
- build hoặc compile an toàn;
- repository-specific validation;
- kiểm tra file nhạy cảm hoặc generated artifact;
- chạy với permissions tối thiểu;
- không phụ thuộc production secrets nếu không thật sự cần thiết.

CI không thay thế code review, nhưng PR không nên merge khi required checks chưa hoàn tất hoặc đang fail.

### 3.4 Human maintainer

Con người chịu trách nhiệm cuối cùng về:

- duyệt thay đổi scope hoặc kiến trúc;
- duyệt dependency/security/production impact;
- xử lý ngoại lệ;
- waive feedback khi có lý do hợp lệ;
- cấu hình branch protection;
- merge Pull Request;
- thực hiện hoặc phê duyệt mutation trên production.

## 4. Thứ tự nguồn sự thật

Khi các nguồn thông tin mâu thuẫn, ưu tiên theo thứ tự:

1. **Source code và tests tại commit hiện tại.**
2. **Merged Pull Requests và approved GitHub Issues.**
3. **Tài liệu canonical đã commit.**
4. **Snapshot trạng thái hiện tại của dự án.**
5. **Local derived tools**, ví dụ code graph.
6. **Chat transcript hoặc ghi chú tạm thời.**

Không dùng output generated, trí nhớ AI hoặc chat cũ để ghi đè lên code và tài liệu hiện tại mà không xác minh.

## 5. Bộ file nên có trong repository

Một repository dùng workflow này nên có tối thiểu:

```text
AGENTS.md
README.md
docs/ai/WORKFLOW.md
docs/ai/CURRENT_STATE.md
.github/ISSUE_TEMPLATE/ai-task.md
.github/pull_request_template.md
.github/workflows/ci.yml
```

Có thể bổ sung:

```text
docs/superpowers/specs/
docs/superpowers/plans/
```

### 5.1 `AGENTS.md`

Đây là hướng dẫn vận hành dành cho coding agent. File nên chứa:

- tổng quan repository và stack;
- thứ tự tài liệu cần đọc;
- architecture và module boundaries;
- coding conventions quan trọng;
- verification commands;
- secret và hosted-system safety;
- quy tắc scope;
- quy trình Pull Request handoff;
- quyền hạn của Codex và con người.

Không ghi quyền quá rộng như:

```text
Codex owns all architecture and risk decisions.
```

Nên ghi rõ:

```text
Codex có thể phân tích và đề xuất. Issue và tài liệu đã được duyệt xác định
scope. Thay đổi material phải được duyệt trước. Con người giữ quyền merge và
production cuối cùng.
```

### 5.2 `docs/ai/WORKFLOW.md`

Mô tả vòng lặp cộng tác chuẩn của repository. File này ổn định và ít thay đổi.

### 5.3 `docs/ai/CURRENT_STATE.md`

Đây là **snapshot ngắn**, không phải nhật ký thời gian.

Nội dung nên có:

- production state;
- current architecture;
- current initiative;
- active Issues và Pull Requests;
- known problems;
- next approved task;
- relevant specs/plans.

Cập nhật khi snapshot trở nên materially stale. Không ghi toàn bộ lịch sử công việc vào đây.

### 5.4 Canonical specs và plans

Có thể sử dụng:

```text
docs/superpowers/specs/
docs/superpowers/plans/
```

Quy tắc:

- spec lưu quyết định thiết kế bền vững;
- plan lưu implementation plan đã được duyệt;
- phải commit nếu được dùng làm nguồn sự thật của team;
- quyết định quan trọng không được chỉ nằm trong chat;
- plan cũ có thể chứa thông tin đã lỗi thời, cần kiểm tra lại với code hiện tại.

Nếu công cụ tạo workspace tạm như:

```text
.superpowers/sdd/
```

thì thư mục đó phải được ignore, không commit và không được dùng làm nguồn sự thật duy nhất.

### 5.5 GitNexus hoặc local code graph

GitNexus có thể dùng để:

- khám phá dependency;
- impact analysis;
- kiểm tra phạm vi thay đổi;
- tìm entry points và module relationships.

Nhưng graph là **local derived data**:

- source code và tests luôn authoritative hơn;
- graph có thể stale;
- phải kiểm tra kết luận lại với source;
- generated graph không commit;
- không bắt buộc đưa GitNexus vào CI khi setup/output chưa ổn định.

Ví dụ ignore rule:

```gitignore
/.gitnexus/
/.superpowers/sdd/
```

## 6. Workflow đầy đủ

## Giai đoạn 0 — Thiết lập ban đầu

Trước task đầu tiên:

1. Kết nối ChatGPT với GitHub repository.
2. Đảm bảo Codex CLI có thể clone/read repository và dùng GitHub CLI hoặc GitHub API cần thiết.
3. Tạo các file hướng dẫn ở mục 5.
4. Tạo Pull Request CI.
5. Xác định branch chính và branch naming convention.
6. Xác định commands chính xác từ repository, không đoán.
7. Xác định secret/generated-file policy.
8. Cấu hình branch protection sau khi CI ổn định nếu team cho phép.

## Giai đoạn 1 — ChatGPT chuẩn bị Issue

ChatGPT đọc:

- trạng thái repository hiện tại;
- `AGENTS.md`;
- `README.md`;
- `CURRENT_STATE.md`;
- specs/plans liên quan;
- Issue/PR trước đó;
- source và tests liên quan.

Issue cần có:

```markdown
## Objective

## Context

## Relevant Documents

## Scope

## Out Of Scope

## Scope Authority
- Approved scope source:
- Expected files:
- Explicitly out of scope:

## Scope Deviations
- Proposed deviation:
- Reason:
- Approval link:

## Stop Conditions

## Acceptance Criteria

## Required Verification

## Security Boundaries

## Production Impact

## Handoff Requirements
```

### Scope rule bắt buộc

```text
Không sửa file ngoài Expected Files hoặc mở rộng Scope nếu Issue chưa được cập
nhật và chưa có phê duyệt rõ ràng. Khi cần vượt scope, dừng và yêu cầu approval.
```

### Stop conditions nên bao gồm

Codex phải dừng khi:

- cần sửa file ngoài expected files;
- cần architecture change chưa được duyệt;
- production impact thay đổi;
- cần dependency mới;
- security boundary thay đổi;
- acceptance criteria không thể đạt trong scope;
- cần secret hoặc quyền truy cập chưa được cấp;
- repository hiện tại khác materially so với context của Issue.

## Giai đoạn 2 — Codex nhận task và triển khai

Người dùng chỉ cần gửi Codex:

```text
Đọc Issue #<NUMBER> trong repository <OWNER/REPO> và triển khai đúng phạm vi.
Tuân thủ AGENTS.md và các tài liệu được Issue liên kết.

Trước khi sửa:
- xác minh branch và working tree;
- đọc current source/tests;
- liệt kê expected files;
- xác nhận stop conditions.

Trong quá trình làm:
- không tự mở rộng scope;
- không đọc hoặc in secret;
- không thay đổi production resources;
- không sửa unrelated user changes.

Sau khi làm:
- review toàn bộ diff;
- chạy verification thực tế;
- ghi chính xác check nào pass/fail/skipped;
- push branch và mở Pull Request liên kết Issue;
- không merge.
```

### Codex nên thực hiện

1. Xác minh repository root.
2. Kiểm tra `git status`.
3. Đọc Issue và `AGENTS.md`.
4. Đọc tài liệu canonical liên quan.
5. Inspect source hiện tại.
6. Lập plan ngắn.
7. Tạo branch riêng.
8. Chỉ sửa file trong scope.
9. Chạy verification.
10. Review diff và scope compliance.
11. Commit có chủ đích.
12. Push và mở PR.

### Codex không nên mặc định dùng

- unrestricted trust;
- auto-accept mọi thay đổi;
- `--yolo`;
- tool delegation có quyền rộng hơn Issue;
- production credentials;
- production mutation.

## Giai đoạn 3 — Codex mở Pull Request

PR phải chứa ít nhất:

```markdown
## Linked Issue

Closes #<NUMBER>

## Summary

## Changed Files

| File | Reason |
| --- | --- |

## Scope Compliance

- [ ] Every changed file is covered by the linked Issue.
- [ ] No Out of Scope work was included.
- [ ] Any scope deviation was approved before implementation.

Approved deviations: None / link

## Acceptance Criteria

## Verification Evidence

| Command | Result |
| --- | --- |

## CI Status

## Risks And Limitations

## Production Impact

## Rollback

## Documentation Updates

## Recommended Next Task
```

PR phải báo cáo đúng sự thật:

- không ghi “passed” nếu command chưa chạy;
- command fail phải ghi nguyên nhân;
- skipped checks phải có lý do;
- deviation phải có approval link được tạo **trước khi implementation**;
- không dùng một deviation chưa được duyệt để tick scope compliant.

## Giai đoạn 4 — CI xác minh độc lập

CI nên:

- chạy khi Pull Request target branch chính;
- dùng minimal permissions;
- cài dependency từ lockfile;
- dùng đúng runtime version của repo;
- chạy lint, tests và build/compile;
- không dùng production secrets cho validation thông thường;
- fail rõ ràng khi có lỗi.

Ví dụ Node.js:

```yaml
name: Pull request quality gates

on:
  pull_request:
    branches:
      - main

permissions:
  contents: read
```

Commands phải lấy từ repository thực tế, ví dụ:

```bash
npm ci
npm run lint
npm test
npm run build
git diff --check
```

Không copy nguyên commands này sang project khác nếu `package.json` hoặc stack không có chúng.

### Artifact safety checks

CI nên fail khi Git đang track:

- PEM/private keys;
- real environment files;
- generated agent workspace;
- generated local graph;
- file nhạy cảm theo chính sách riêng của dự án.

Chỉ in **path**, không in content của secret.

Cho phép các file template an toàn như:

```text
.env.example
.env.production.example
```

khi project sử dụng chúng.

## Giai đoạn 5 — ChatGPT review Pull Request

Prompt mẫu:

```text
Đọc Issue #<ISSUE> và Pull Request #<PR> của <OWNER/REPO>.

Review implementation dựa trên:
- Issue và acceptance criteria;
- canonical specs/plans;
- toàn bộ diff;
- CI result;
- scope compliance;
- security và production boundaries.

Kiểm tra:
1. Có đáp ứng đầy đủ acceptance criteria không?
2. Có file nào ngoài expected scope không?
3. Có bug, regression hoặc thiếu test không?
4. Verification evidence có đúng với CI không?
5. Có secret, generated artifact hoặc production impact ngoài dự kiến không?
6. Docs và CURRENT_STATE có bị stale không?

Phân loại:
- BLOCKER
- SHOULD FIX
- OPTIONAL

Kết luận:
- APPROVE
- REQUEST CHANGES
- NEEDS MANUAL CHECK

Ghi feedback actionable trực tiếp trên Pull Request. Không merge.
```

### Review priority

ChatGPT nên review theo thứ tự:

1. security và data loss;
2. scope violation;
3. correctness;
4. backward compatibility;
5. tests và verification;
6. architecture boundaries;
7. maintainability;
8. docs;
9. style nhỏ.

Feedback tốt phải chứa:

- vị trí hoặc file liên quan;
- vấn đề cụ thể;
- ảnh hưởng;
- điều kiện để được xem là resolved;
- mức độ ưu tiên.

## Giai đoạn 6 — Codex xử lý feedback

Prompt mẫu:

```text
Đọc review comments mới nhất trên Pull Request #<PR> của <OWNER/REPO>.

- Chỉ xử lý feedback actionable và nằm trong scope đã duyệt.
- Nếu feedback yêu cầu mở rộng scope, dependency, architecture, security hoặc
  production impact, dừng và yêu cầu cập nhật Issue/approval trước.
- Sửa trên cùng branch của Pull Request.
- Chạy lại checks liên quan.
- Cập nhật verification evidence và trả lời từng review thread.
- Không merge.
```

Sau khi sửa, Codex phải:

- rebase/sync khi cần và an toàn;
- review diff mới;
- rerun relevant checks;
- cập nhật PR body nếu changed files hoặc risks thay đổi;
- trả lời review comment bằng evidence;
- không tự resolve một concern chưa thực sự xử lý.

## Giai đoạn 7 — Final review và merge

ChatGPT kiểm tra lại:

- required CI đã pass;
- blocker đã resolved;
- scope deviations có approval;
- PR body phản ánh diff cuối;
- không có secret/generated artifacts;
- documentation cần thiết đã cập nhật.

Con người sau đó:

- đọc kết luận review;
- quyết định waive hay yêu cầu sửa;
- kiểm tra production impact;
- merge bằng policy của repository;
- thực hiện deployment hoặc production mutation riêng nếu đã được duyệt.

Không nên để AI tự merge mặc định.

## Giai đoạn 8 — Sau merge

Sau khi merge:

1. Đóng Issue nếu chưa tự đóng.
2. Cập nhật `CURRENT_STATE.md` nếu snapshot đã stale.
3. Không biến `CURRENT_STATE.md` thành chronological log.
4. Tạo Issue mới cho follow-up thay vì nhét thêm scope vào task đã merge.
5. Audit workflow nếu PR được merge trước khi review/CI hoàn tất.
6. Cân nhắc branch protection khi CI đã ổn định.

## 7. Scope deviation protocol

Một deviation chỉ hợp lệ khi:

1. Codex phát hiện yêu cầu vượt scope.
2. Codex dừng trước khi sửa phần vượt scope.
3. Lý do và thay đổi đề xuất được ghi trên Issue.
4. Người có thẩm quyền approve rõ ràng.
5. Approval link được ghi vào Issue và PR.
6. Codex mới tiếp tục implementation.

Không hợp lệ:

- sửa trước rồi xin phép sau;
- ghi deviation trong PR nhưng không có approval;
- tự đổi acceptance criteria để làm CI green;
- “tiện tay” refactor file ngoài task;
- thêm dependency mà không báo;
- thay đổi production behavior ngầm.

## 8. Secret và production safety

Agent không được:

- đọc hoặc in private key;
- đọc hoặc in giá trị `.env`;
- commit PEM, token, database password hoặc signed URL;
- sao chép production secret vào GitHub Actions;
- mutate AWS, Supabase, DNS, TLS hoặc production database khi Issue chỉ cho phép sửa code;
- gửi payload chứa dữ liệu cá nhân vào log hoặc PR.

Agent có thể:

- kiểm tra tên/path của file mà không đọc content;
- sử dụng placeholder an toàn;
- cập nhật `.env.example` khi Issue cho phép;
- đề xuất một task production riêng;
- mô tả target, operation, effect, evidence và rollback trước hosted mutation.

## 9. Hai mức workflow

### 9.1 Workflow đầy đủ — khuyến nghị cho production

```text
Issue → Codex branch → PR → CI → ChatGPT review → Codex fixes → Human merge
```

Dùng cho:

- production repository;
- nhiều thành viên;
- thay đổi backend/database;
- security-sensitive work;
- task có dependency hoặc architecture impact.

### 9.2 Workflow nhẹ — task nhỏ, rủi ro thấp

```text
Issue hoặc task note rõ scope → Codex patch → local checks → Human review
```

Chỉ nên dùng khi:

- repository cá nhân;
- thay đổi nhỏ;
- không có production/security impact;
- không cần lưu conversation dài hạn.

Ngay cả workflow nhẹ vẫn phải có scope, verification và human approval.

## 10. Cách chuyển workflow sang project mới

Thực hiện checklist sau:

### Repository discovery

- [ ] Xác định stack và runtime version.
- [ ] Xác định package manager và lockfile.
- [ ] Xác định lint/test/build commands thực tế.
- [ ] Xác định deployment workflow.
- [ ] Xác định architecture/module boundaries.
- [ ] Xác định secret và data boundaries.

### Collaboration files

- [ ] Tạo hoặc cập nhật `AGENTS.md`.
- [ ] Tạo `docs/ai/WORKFLOW.md`.
- [ ] Tạo `docs/ai/CURRENT_STATE.md`.
- [ ] Tạo AI Issue template.
- [ ] Cập nhật PR template.
- [ ] Tạo PR quality-gate workflow.

### Repository safety

- [ ] Ignore generated AI workspace.
- [ ] Ignore local code graph.
- [ ] Reject tracked private keys.
- [ ] Reject real environment files.
- [ ] Allowlist example environment files.
- [ ] Không dùng production secrets trong PR CI.

### Governance

- [ ] Issue là scope authority.
- [ ] Codex có stop conditions.
- [ ] Scope deviation cần prior approval.
- [ ] ChatGPT review trước merge.
- [ ] Human giữ merge authority.
- [ ] Branch protection được cân nhắc sau khi CI ổn định.

## 11. Prompt khởi tạo nhanh cho ChatGPT ở project mới

```text
Đọc repository <OWNER/REPO> và thiết lập collaboration workflow giữa ChatGPT
Web, Codex CLI và GitHub.

Mục tiêu:
- GitHub Issue là task và scope authority;
- Codex implement trên branch riêng;
- Pull Request là handoff report;
- GitHub Actions xác minh độc lập;
- ChatGPT review Issue + diff + CI;
- Codex sửa feedback;
- con người phê duyệt và merge.

Trước tiên chỉ phân tích repository hiện tại:
1. stack, runtime, package manager;
2. lint/test/build scripts;
3. architecture boundaries;
4. workflows hiện có;
5. secret và generated-file risks;
6. tài liệu hướng dẫn agent hiện có.

Sau đó đề xuất một Issue giới hạn ở collaboration documentation, templates và
CI. Không sửa application source, dependency hoặc production behavior nếu chưa
được phê duyệt.
```

## 12. Prompt khởi tạo nhanh cho Codex ở project mới

```text
Bạn đang làm việc trong repository <OWNER/REPO>.

Đọc theo thứ tự:
1. linked GitHub Issue;
2. AGENTS.md;
3. README.md;
4. docs/ai/CURRENT_STATE.md;
5. specs/plans liên quan;
6. source và tests được Issue chỉ định;
7. docs/ai/WORKFLOW.md trước khi handoff.

Issue là scope authority. Không sửa file ngoài Expected Files hoặc mở rộng scope
nếu chưa có prior approval được ghi trên GitHub.

Không đọc/in/commit secret. Không mutate production resources. Không sử dụng
unrestricted trust hoặc --yolo làm mặc định.

Sau implementation:
- review toàn bộ diff;
- chạy verification thật;
- báo chính xác pass/fail/skipped;
- mở Pull Request liên kết Issue;
- chờ CI và ChatGPT review;
- không merge.
```

## 13. Bản tóm tắt một phút

```text
1. ChatGPT biến yêu cầu thành GitHub Issue rõ scope.
2. Codex đọc Issue, AGENTS.md và tài liệu canonical.
3. Codex làm trên branch riêng, không vượt expected files.
4. Codex chạy checks, tự review diff và mở PR.
5. GitHub Actions kiểm tra độc lập.
6. ChatGPT review Issue + diff + CI và ghi feedback lên PR.
7. Codex sửa feedback trong cùng branch.
8. ChatGPT xác nhận kết quả.
9. Con người quyết định merge và production action.
10. Mọi thay đổi ngoài scope phải được approve trước khi sửa.
```

## 14. Cách sử dụng tài liệu này

Khi tham gia team hoặc project mới, gửi cho AI:

1. file này;
2. repository URL;
3. Issue hoặc mục tiêu hiện tại;
4. quyền truy cập được phép;
5. các giới hạn production/security đặc biệt.

Yêu cầu AI đọc file này như **collaboration baseline**, sau đó điều chỉnh commands, paths và architecture theo repository thực tế. Không được copy mù quáng stack, scripts hoặc CI commands từ project cũ.

---

## Nguồn hình thành

Playbook này được tổng hợp từ một workflow đã triển khai thực tế trong dự án Feaon:

- GitHub được chọn làm communication protocol;
- canonical specs/plans được commit;
- workspace SDD và GitNexus graph được giữ local;
- scope controls được đưa vào Issue/PR templates;
- PR CI xác minh độc lập;
- ChatGPT review trước human merge;
- Codex không có quyền tự mở rộng scope hoặc tự quyết định production changes.
