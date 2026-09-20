# AI Agent Memory Architecture Guide

## Purpose

Hướng dẫn thiết kế memory cho AI agent theo cách có thể kiểm soát, truy vết và
cập nhật. Tài liệu tập trung vào quyết định kiến trúc: thông tin nào đáng nhớ,
lưu ở tầng nào, truy xuất khi nào, xử lý xung đột ra sao và khi nào phải xóa.

Memory trong tài liệu này là trạng thái được lưu ngoài lần gọi model hiện tại.
Nó không đồng nghĩa với toàn bộ lịch sử hội thoại, vector database hoặc
Retrieval-Augmented Generation (RAG).

## When to use

- Thiết kế agent cần tiếp tục công việc qua nhiều lượt hoặc nhiều session.
- Agent phải nhớ preference, quyết định dự án, kết quả task hoặc quy trình.
- Audit một hệ thống đang trả về memory cũ, trùng, sai scope hoặc không liên quan.
- Chọn giữa structured lookup, full-text search, vector search và hybrid search.
- Thiết kế quyền xem, cập nhật, hết hạn và xóa memory.

Không dùng tài liệu này như hướng dẫn chọn một sản phẩm vector database cụ thể.

## Preconditions

Trước khi thiết kế memory, xác định:

- actor nào tạo, đọc, sửa và xóa memory;
- scope của dữ liệu: user, organization, project, agent hoặc task;
- nguồn sự thật có thể xác minh cho từng loại thông tin;
- dữ liệu nhạy cảm hoặc dữ liệu bị cấm lưu;
- yêu cầu retention, deletion, audit và quyền sửa của người dùng;
- context budget và latency budget của agent;
- metric thể hiện agent thực sự làm việc tốt hơn nhờ memory.

Nếu chưa trả lời được các câu hỏi này, chỉ giữ state trong working memory. Không
ghi lâu dài theo mặc định.

## Mental model

Thiết kế memory theo hai trục độc lập: tầng lưu trữ và loại nội dung. Không dùng
một taxonomy thay cho taxonomy còn lại.

### Storage layers

| Layer | Lifetime | Nội dung phù hợp | Cách truy cập điển hình |
|---|---|---|---|
| Working memory | Một bước hoặc một task đang chạy | Mục tiêu hiện tại, tool result gần nhất, pending action | Luôn có trong context hoặc task state |
| Session memory | Một phiên làm việc | Tóm tắt hội thoại, lựa chọn tạm thời, tiến độ | Theo session ID |
| Long-term memory | Nhiều session | Preference bền vững, quyết định, kết quả đã xác minh | Structured, full-text, vector hoặc hybrid retrieval |
| Knowledge base | Độc lập với lịch sử agent | Tài liệu, source code, policy, catalog | RAG hoặc query theo nguồn |

Working memory ưu tiên tính mới và đầy đủ cho task hiện tại. Long-term memory ưu
tiên tính đúng, scope rõ và khả năng cập nhật.

### Content types

| Type | Câu hỏi trả lời | Ví dụ |
|---|---|---|
| Episodic | Chuyện gì đã xảy ra, khi nào và kết quả gì? | Một deployment thất bại do migration |
| Semantic | Fact hoặc quyết định nào đang có hiệu lực? | Dự án dùng PostgreSQL và Next.js |
| Procedural | Công việc phải được thực hiện như thế nào? | Chạy test, typecheck và migration check trước deploy |

Một record có thể là `semantic` trong `long-term memory`, hoặc `episodic` chỉ tồn
tại trong `session memory`. Type không quyết định lifetime.

## Reference architecture

```text
User request
    |
    v
Scope and policy gate
    |
    +--> Working/session state
    |
    +--> Long-term memory retrieval
    |
    +--> Knowledge-base retrieval
    |
    v
Context assembly
    |
    v
Model and tools
    |
    v
Candidate memory extraction
    |
    v
Validation, deduplication and write policy
    |
    v
Memory store and audit log
```

Retrieval và write-back là hai policy riêng. Việc agent đọc được một record không
có nghĩa agent được phép sửa hoặc tạo record cùng scope.

## Decide what to remember

Chỉ ghi long-term memory khi thông tin vượt qua toàn bộ gate sau:

1. **Useful later:** có use case cụ thể trong session tương lai.
2. **Stable enough:** không phải trạng thái thoáng qua hoặc phỏng đoán ngắn hạn.
3. **Sourceable:** có nguồn và thời điểm tạo để người khác kiểm tra.
4. **Scoped:** biết record thuộc user, project, organization hoặc agent nào.
5. **Permitted:** policy cho phép lưu loại dữ liệu này.
6. **Maintainable:** có cách supersede, expire hoặc delete record.

Không ghi lâu dài:

- toàn bộ transcript chỉ vì có thể lưu;
- chain-of-thought hoặc reasoning ẩn của model;
- secret, credential, private key hoặc raw authentication state;
- dữ liệu cá nhân không cần thiết cho use case;
- output chưa được xác minh nhưng được diễn đạt như fact;
- tool result có hiệu lực ngắn mà không có expiration;
- bản sao của tài liệu đã có nguồn canonical.

## Memory lifecycle

### 1. Observe

Thu nhận event, user statement, tool result hoặc thay đổi trạng thái. Giữ nguyên
source reference thay vì chỉ lưu bản tóm tắt mất provenance.

### 2. Qualify

Phân loại candidate theo type, scope, sensitivity, confidence và lifetime. Áp
dụng write policy trước khi tạo embedding hoặc ghi database.

### 3. Normalize

Chuẩn hóa một fact hoặc outcome cho mỗi record. Tách event khỏi kết luận được suy
ra từ event đó và đánh dấu inference rõ ràng.

### 4. Deduplicate and resolve

So candidate với record hiện có trong cùng scope. Chọn một trong bốn hành động:

- bỏ qua vì trùng hoàn toàn;
- cập nhật metadata hoặc access count;
- tạo version mới và đánh dấu record cũ đã bị supersede;
- giữ song song vì hai record nói về scope hoặc thời điểm khác nhau.

Không âm thầm overwrite khi hai nguồn mâu thuẫn.

### 5. Store

Ghi content cùng provenance, version, timestamps và policy metadata. Embedding là
index có thể tái tạo, không phải nguồn sự thật duy nhất.

### 6. Retrieve

Lọc theo authorization, scope, validity và type trước khi xếp hạng relevance.
Không để similarity score vượt qua access control hoặc expiration.

### 7. Validate at use time

Kiểm tra memory còn hiệu lực trước khi dùng cho quyết định có tác động. Với dữ
liệu dễ thay đổi, re-read nguồn canonical hoặc nói rõ thông tin có thể đã cũ.

### 8. Supersede, expire or delete

Preference mới phải supersede preference cũ. Event hết giá trị phải expire.
Yêu cầu xóa phải loại record, index dẫn xuất và cache liên quan theo policy.

## Memory record contract

Schema dưới đây là điểm bắt đầu, không phải schema bắt buộc cho mọi hệ thống:

```json
{
  "id": "memory_1234567890123",
  "content": "The project uses PostgreSQL",
  "type": "semantic",
  "scope": {
    "tenant_id": "tenant_1234567890123",
    "project_id": "project_1234567890123"
  },
  "source": {
    "kind": "repository",
    "ref": "docs/architecture.md",
    "observed_at": "2026-09-20T12:00:00Z"
  },
  "confidence": 0.95,
  "sensitivity": "internal",
  "valid_from": "2026-09-20T12:00:00Z",
  "expires_at": null,
  "supersedes": null,
  "created_at": "2026-09-20T12:00:00Z",
  "updated_at": "2026-09-20T12:00:00Z"
}
```

Các field tối thiểu nên trả lời được:

- nội dung nói gì;
- thuộc loại và scope nào;
- đến từ đâu và được quan sát khi nào;
- có hiệu lực trong khoảng nào;
- mức nhạy cảm và quyền truy cập;
- record nào đã bị thay thế;
- ai hoặc process nào tạo và cập nhật.

Confidence không biến một inference thành fact. Luôn giữ `source.kind` và trạng
thái inference riêng nếu record không đến trực tiếp từ nguồn canonical.

## Choose a retrieval strategy

| Strategy | Phù hợp khi | Không nên dùng làm lựa chọn duy nhất khi |
|---|---|---|
| Structured lookup | Có key và scope rõ như `user_id`, `project_id`, `type` | Query diễn đạt tự nhiên và không biết key |
| Full-text search | Từ khóa, identifier và exact phrase quan trọng | Cùng ý nghĩa nhưng khác từ vựng |
| Vector search | Cần semantic similarity trên nội dung phi cấu trúc | Cần exact match, authorization hoặc time validity |
| Hybrid search | Cần kết hợp filter, keyword và semantic rank | Dataset nhỏ và structured lookup đã đủ |

Pipeline retrieval nên chạy theo thứ tự:

1. authorization và tenant isolation;
2. scope, validity, type và sensitivity filters;
3. candidate retrieval;
4. relevance, recency và source-quality ranking;
5. deduplication và contradiction handling;
6. context-budget selection;
7. provenance attachment cho output.

Vector database là một implementation option. Dataset nhỏ có thể dùng
PostgreSQL, full-text index hoặc structured table mà không cần thêm hệ thống.

## Handle conflicts and stale memory

Khi hai record mâu thuẫn, ưu tiên theo policy được công bố, ví dụ:

1. explicit user correction trong đúng scope;
2. nguồn canonical hiện tại;
3. record có version hoặc timestamp mới hơn;
4. tool evidence đã xác minh;
5. inference hoặc summary do model tạo.

Nếu policy không chọn được nguồn thắng, đưa xung đột vào context thay vì tự hợp
nhất thành một fact. Với quyết định có tác động, yêu cầu xác minh trước khi hành
động.

## Privacy and security

- Áp dụng tenant isolation trước retrieval và trước write.
- Mã hóa dữ liệu nhạy cảm khi lưu và khi truyền nếu threat model yêu cầu.
- Giới hạn raw transcript; ưu tiên record tối thiểu phục vụ use case.
- Tách memory dùng cho personalization khỏi audit log bất biến.
- Cho phép người dùng xem, sửa và xóa memory liên quan đến họ khi policy yêu cầu.
- Ghi audit event cho write, update, supersede và delete.
- Không đưa secret vào embedding hoặc external vector service.
- Kiểm tra prompt injection trong content được retrieval từ nguồn bên ngoài.

## Workflow

### 1. Define use cases

Viết 3 đến 5 tình huống cụ thể mà memory phải cải thiện. Mỗi tình huống phải nêu
input, memory cần lấy và hành vi mong đợi.

### 2. Define policy before storage

Lập bảng type, scope, lifetime, allowed writers, allowed readers và deletion
rule. Không chọn database trước khi policy rõ.

### 3. Start with the smallest layer

Ưu tiên working/session state. Chỉ thêm long-term memory cho use case đã chứng
minh cần persistence.

### 4. Implement provenance and versioning

Mọi record persistent phải có source, timestamps và cơ chế supersede hoặc
expire trước khi bật automatic write-back.

### 5. Add retrieval incrementally

Bắt đầu bằng structured filters. Thêm full-text hoặc vector search khi test set
cho thấy structured retrieval không đáp ứng.

### 6. Evaluate with and without memory

So sánh cùng task set ở hai cấu hình. Memory chỉ có giá trị nếu tăng chất lượng
task mà không tạo tỷ lệ stale, conflict hoặc privacy violation không chấp nhận
được.

## Validation

Trước khi release, kiểm tra:

- [ ] Mỗi record có type, scope, source và validity.
- [ ] Authorization chạy trước similarity search.
- [ ] Duplicate write tạo no-op hoặc version có chủ đích.
- [ ] User correction supersede record cũ.
- [ ] Expired record không vào context.
- [ ] Conflicting records không bị hợp nhất âm thầm.
- [ ] Delete loại record và index/cache dẫn xuất theo policy.
- [ ] Secret và dữ liệu bị cấm không được ghi hoặc embed.
- [ ] Retrieval có provenance trong trace hoặc output nội bộ.
- [ ] Test set bao gồm irrelevant, stale, duplicate và cross-tenant candidates.
- [ ] Có baseline không dùng memory để đo lợi ích thực.

Các metric hữu ích:

- task success rate với và không có memory;
- retrieval precision trên tập query đã gán nhãn;
- stale-memory retrieval rate;
- contradiction rate trong context;
- cross-scope leakage count;
- token, latency và storage cost trên mỗi task;
- correction và deletion completion rate.

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| Agent nhắc preference cũ | Record mới không supersede record cũ | Thêm version chain và lọc active record |
| Query trả nhiều nội dung gần nghĩa nhưng sai task | Chỉ dùng vector similarity | Thêm scope/type/time filters và reranking |
| Cùng fact xuất hiện nhiều lần | Write path thiếu deduplication | Tạo canonical key hoặc similarity threshold trong cùng scope |
| Agent dùng fact từ project khác | Tenant hoặc project filter chạy sau retrieval | Đưa authorization và scope filter lên đầu pipeline |
| Context phình to qua thời gian | Lưu transcript thay vì record tối thiểu | Tóm tắt có provenance, expire session state và giới hạn top-k |
| Không thể giải thích vì sao agent biết một fact | Record thiếu source | Chặn persistent write nếu không có provenance |
| Xóa record nhưng agent vẫn nhắc lại | Embedding hoặc cache chưa bị xóa | Cascade delete và invalidation cho mọi derived index |
| Vector search không cải thiện kết quả | Dataset hoặc query phù hợp exact lookup hơn | Quay về structured/full-text baseline và đo lại |

## References

- [MemGPT: Towards LLMs as Operating Systems](https://arxiv.org/abs/2310.08560)
- [Generative Agents: Interactive Simulacra of Human Behavior](https://arxiv.org/abs/2304.03442)
- [Letta memory blocks](https://docs.letta.com/guides/agents/memory-blocks/)
- [PostgreSQL full-text search](https://www.postgresql.org/docs/current/textsearch.html)
- [pgvector](https://github.com/pgvector/pgvector)
