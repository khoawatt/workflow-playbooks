Agile & Scrum Interview Study Notes

Tài liệu ôn phỏng vấn Backend / Fullstack Software Engineer

**\
BỘ 22 CÂU HỎI PHỎNG VẤN\
AGILE & SCRUM**

*Dành cho Backend / Fullstack / Software Engineer 1.5–3 năm kinh nghiệm*

Phiên bản học nhanh để trả lời phỏng vấn theo hướng thực tế dự án

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>Mục tiêu tài liệu</strong></p>
<p>Giúp bạn không chỉ học thuộc định nghĩa Agile/Scrum, mà còn biết trả lời theo ngữ cảnh dự án thật: requirement thay đổi, Sprint không hoàn thành, Daily bị hình thức, backlog chưa rõ, velocity bị dùng sai, và cách xử lý scope change.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# Cách sử dụng tài liệu

Tài liệu này được thiết kế theo dạng phỏng vấn hỏi đáp. Với mỗi câu, bạn nên học theo ba lớp: hiểu ý chính, tự nói lại bằng ngôn ngữ của mình, sau đó so sánh với câu trả lời mẫu để bổ sung các keyword quan trọng.

1.  Đọc phần “Ý cần nắm” để hiểu interviewer đang muốn kiểm tra điều gì.

2.  Tự trả lời miệng trong 1–2 phút như đang phỏng vấn thật.

3.  So sánh với “Câu trả lời mẫu” và ghi nhớ các cụm quan trọng.

4.  Xem “Lỗi cần tránh” để không rơi vào các hiểu nhầm phổ biến khi nói về Agile/Scrum.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<th><p><strong>Nguyên tắc trả lời khi phỏng vấn</strong></p>
<p>Đừng chỉ học thuộc định nghĩa. Hãy luôn kết nối câu trả lời với thực tế dự án: backlog, priority, stakeholder, Sprint Goal, Definition of Done, scope, quality, risk và feedback loop.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# Nguồn tham khảo chính

Các định nghĩa nền tảng trong tài liệu được đối chiếu với nguồn chính thức sau:

- Agile Manifesto: [<u>agilemanifesto.org</u>](https://agilemanifesto.org/)

- 12 Agile Principles: [<u>agilemanifesto.org/principles.html</u>](https://agilemanifesto.org/principles.html)

- The Scrum Guide 2020: [<u>scrumguides.org/scrum-guide.html</u>](https://scrumguides.org/scrum-guide.html)

# Mục lục câu hỏi

## Nhóm 1: Agile Foundation

> Câu 1. Agile là gì? Vì sao nhiều team phần mềm dùng Agile thay vì Waterfall?
>
> Câu 2. Agile Manifesto có 4 giá trị nào? Theo bạn giá trị nào quan trọng nhất?
>
> Câu 3. Agile khác Waterfall như thế nào? Khi nào nên dùng Waterfall thay vì Agile?
>
> Câu 4. Agile có phải là không cần documentation không?

## Nhóm 2: Scrum Basic

> Câu 5. Scrum là gì? Scrum khác Agile như thế nào?
>
> Câu 6. Trong Scrum có những role/accountability nào? Trách nhiệm của từng role là gì?
>
> Câu 7. Product Owner khác Project Manager như thế nào?
>
> Câu 8. Scrum Master có phải team lead hoặc manager không?
>
> Câu 9. Developer trong Scrum chỉ có coder không?

## Nhóm 3: Scrum Events / Ceremonies

> Câu 10. Sprint là gì? Một Sprint thường kéo dài bao lâu?
>
> Câu 11. Sprint Planning là gì? Team cần làm gì trong buổi này?
>
> Câu 12. Daily Scrum là gì? Có phải buổi báo cáo cho manager không?
>
> Câu 13. Sprint Review khác Sprint Retrospective như thế nào?
>
> Câu 14. Nếu Daily Scrum kéo dài quá lâu thì xử lý thế nào?

## Nhóm 4: Scrum Artifacts & Backlog

> Câu 15. Product Backlog, Sprint Backlog và Increment là gì?
>
> Câu 16. User Story là gì? Một User Story tốt nên như thế nào?
>
> Câu 17. Definition of Done là gì? Vì sao quan trọng?
>
> Câu 18. Story Point là gì? Nó khác estimate theo giờ như thế nào?
>
> Câu 19. Velocity là gì? Có nên dùng velocity để ép team tăng năng suất không?

## Nhóm 5: Real Project Scenarios & Senior Mindset

> Câu 20. Nếu khách hàng muốn thêm requirement giữa Sprint thì bạn xử lý thế nào?
>
> Câu 21. Nếu team không hoàn thành hết Sprint Backlog thì nên làm gì?
>
> Câu 22. Nếu bạn thấy Scrum trong team chỉ làm hình thức, Daily vẫn họp nhưng không giải quyết vấn đề, bạn sẽ cải thiện thế nào?

# Nhóm 1: Agile Foundation

## Câu 1. Agile là gì? Vì sao nhiều team phần mềm dùng Agile thay vì Waterfall?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Agile là mindset/cách tiếp cận phát triển phần mềm theo vòng lặp ngắn và tăng trưởng dần.

- Mục tiêu là delivery sớm, nhận feedback thường xuyên và thích ứng với thay đổi.

- Waterfall phù hợp với yêu cầu ổn định; Agile phù hợp khi requirement có thể thay đổi hoặc cần kiểm chứng liên tục.

### Câu trả lời mẫu

Agile là một mindset và cách tiếp cận phát triển phần mềm theo hướng iterative và incremental. Thay vì cố gắng chốt toàn bộ requirement, design, development và testing ngay từ đầu, Agile chia quá trình phát triển thành các vòng lặp ngắn để team có thể liên tục tạo ra phần sản phẩm có giá trị, nhận feedback và điều chỉnh hướng đi.

Nhiều team dùng Agile thay vì Waterfall vì phần mềm thường có nhiều yếu tố không chắc chắn. Requirement ban đầu có thể chưa đầy đủ, khách hàng có thể thay đổi ưu tiên sau khi nhìn thấy sản phẩm thật, hoặc thị trường thay đổi trong quá trình phát triển. Nếu dùng Waterfall, team thường chỉ phát hiện vấn đề lớn ở giai đoạn cuối, khi chi phí sửa đổi đã cao. Với Agile, team có thể demo sớm, kiểm chứng giả định sớm và giảm rủi ro xây sai sản phẩm.

Tuy nhiên Agile không có nghĩa là làm tùy hứng hoặc thay đổi vô kiểm soát. Team vẫn cần backlog, priority, planning, estimation, review và agreement rõ ràng với stakeholder để việc thay đổi được quản lý hợp lý.

### Lỗi cần tránh / cách nói hay hơn

- Không nên nói Agile là “muốn đổi gì cũng đổi ngay lập tức”. Agile là thích ứng có kiểm soát.

- Không nên nói Waterfall luôn xấu. Waterfall vẫn có thể phù hợp khi yêu cầu rất rõ và ít thay đổi.

- Nên dùng từ “increment” thay vì chỉ nói “module”, vì increment là phần sản phẩm hoàn thành có giá trị và có thể kiểm chứng.

## Câu 2. Agile Manifesto có 4 giá trị nào? Theo bạn giá trị nào quan trọng nhất?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Nắm được 4 giá trị: individuals/interactions, working software, customer collaboration, responding to change.

- Hiểu “over” không có nghĩa bỏ vế sau, mà là ưu tiên vế trước hơn khi cần đánh đổi.

- Biết chọn một giá trị và giải thích bằng bối cảnh thực tế.

### Câu trả lời mẫu

Agile Manifesto có 4 giá trị cốt lõi. Thứ nhất là cá nhân và sự tương tác hơn là quy trình và công cụ. Thứ hai là phần mềm chạy được hơn là tài liệu đầy đủ. Thứ ba là hợp tác với khách hàng hơn là đàm phán hợp đồng. Thứ tư là thích ứng với thay đổi hơn là bám sát kế hoạch.

Điểm quan trọng là chữ “over” không có nghĩa Agile bỏ qua quy trình, công cụ, tài liệu, hợp đồng hay kế hoạch. Những thứ đó vẫn có giá trị, nhưng khi cần ưu tiên thì Agile ưu tiên con người, sản phẩm hoạt động được, sự hợp tác và khả năng thích ứng.

Nếu phải chọn một giá trị quan trọng nhất trong môi trường làm phần mềm thực tế, tôi chọn “responding to change over following a plan”. Lý do là requirement ban đầu thường dựa trên giả định. Khi khách hàng dùng thử hoặc nhìn thấy increment, họ có thể nhận ra nhu cầu thực tế khác đi. Nếu team bám cứng vào kế hoạch ban đầu, team có thể delivery đúng plan nhưng lại xây sai sản phẩm.

Tuy nhiên thích ứng với thay đổi không có nghĩa là thay đổi tùy tiện. Team cần đưa thay đổi vào backlog, đánh giá priority, effort và impact tới scope, timeline, cost, sau đó thống nhất với Product Owner hoặc stakeholder.

### Lỗi cần tránh / cách nói hay hơn

- Không dịch “responding to change” thành “phản hồi thay đổi”; nên nói “thích ứng với thay đổi”.

- Không nói Agile không cần tài liệu hoặc không cần kế hoạch.

- Khi chọn giá trị quan trọng nhất, nên liên hệ với vai trò đang phỏng vấn: dev thường có thể chọn working software; outsource có thể chọn responding to change; team process có thể chọn individuals and interactions.

## Câu 3. Agile khác Waterfall như thế nào? Khi nào nên dùng Waterfall thay vì Agile?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Agile: lặp, tăng trưởng dần, feedback thường xuyên, dễ điều chỉnh.

- Waterfall: tuần tự, từng phase rõ ràng, thay đổi muộn tốn chi phí.

- Waterfall phù hợp khi requirement ổn định, compliance cao, scope rõ và ít biến động.

### Câu trả lời mẫu

Agile và Waterfall khác nhau chủ yếu ở cách quản lý sự không chắc chắn. Waterfall đi theo mô hình tuần tự: requirement, design, implementation, testing, deployment. Mỗi giai đoạn thường cần hoàn thành tương đối đầy đủ trước khi chuyển sang giai đoạn sau. Cách làm này giúp dễ quản lý kế hoạch nếu requirement đã rõ, nhưng nếu phát hiện sai requirement ở cuối dự án thì chi phí sửa đổi rất cao.

Agile thì chia dự án thành các vòng lặp ngắn. Sau mỗi vòng lặp, team cố gắng tạo ra một increment có thể review, test hoặc release. Nhờ đó, khách hàng và stakeholder có thể phản hồi sớm, còn team có thể điều chỉnh backlog và priority trước khi đi quá xa theo hướng sai.

Tuy vậy không phải dự án nào cũng bắt buộc dùng Agile. Waterfall có thể phù hợp khi requirement rất rõ ràng, ít thay đổi, dự án có nhiều ràng buộc pháp lý hoặc cần tài liệu/phê duyệt theo từng phase. Ví dụ một số dự án government, compliance, xây dựng hệ thống theo contract cố định hoặc migration có scope rõ có thể dùng Waterfall hoặc hybrid.

### Lỗi cần tránh / cách nói hay hơn

- Không trả lời theo kiểu Agile tốt tuyệt đối, Waterfall lỗi thời tuyệt đối.

- Nên nhấn mạnh “phù hợp bối cảnh” thay vì chọn một mô hình cho mọi trường hợp.

- Nếu nói về nhược điểm Agile, hãy nhắc scope creep, estimation khó, cần PO/stakeholder active.

## Câu 4. Agile có phải là không cần documentation không?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Agile không loại bỏ tài liệu.

- Agile ưu tiên tài liệu đủ dùng, đúng thời điểm, phục vụ delivery và maintenance.

- Ví dụ tài liệu cần thiết: API docs, architecture decisions, onboarding, runbook, security notes.

### Câu trả lời mẫu

Không. Agile không nói rằng team không cần documentation. Agile chỉ nói working software quan trọng hơn comprehensive documentation. Nghĩa là tài liệu vẫn có giá trị, nhưng tài liệu không nên trở thành mục tiêu chính thay cho việc tạo ra phần mềm hoạt động được và có giá trị.

Trong thực tế, một team Agile tốt vẫn cần tài liệu đủ dùng. Ví dụ backend team cần API documentation, database schema notes, architecture decision records, deployment guide, runbook vận hành, security guideline và onboarding document cho người mới. Các tài liệu này giúp team maintain hệ thống, onboard nhanh hơn và giảm phụ thuộc vào một vài cá nhân.

Điểm khác biệt là Agile tránh việc viết tài liệu quá nặng, quá sớm hoặc không ai sử dụng. Tài liệu nên ngắn gọn, cập nhật được, gắn với nhu cầu thực tế và hỗ trợ delivery.

### Lỗi cần tránh / cách nói hay hơn

- Không nói “Agile không cần tài liệu”. Đây là hiểu sai rất phổ biến.

- Không viết tài liệu chỉ để đủ quy trình nhưng không phục vụ người đọc.

- Nên dùng cụm “just enough documentation” hoặc “living documentation” nếu muốn trả lời chuyên nghiệp hơn.

# Nhóm 2: Scrum Basic

## Câu 5. Scrum là gì? Scrum khác Agile như thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Agile là mindset/giá trị/nguyên tắc.

- Scrum là framework cụ thể để áp dụng Agile.

- Scrum có accountabilities/roles, events, artifacts và commitments.

### Câu trả lời mẫu

Scrum là một framework nhẹ giúp team phát triển sản phẩm trong môi trường phức tạp bằng cách chia công việc thành các Sprint ngắn, thường kéo dài từ 1 đến 4 tuần. Trong mỗi Sprint, Scrum Team hướng tới một Sprint Goal và tạo ra một increment có giá trị, có thể kiểm chứng.

Scrum khác Agile ở chỗ Agile là mindset, bao gồm các giá trị và nguyên tắc chung về cách phát triển phần mềm linh hoạt. Scrum là một framework cụ thể để triển khai tinh thần Agile trong thực tế. Scrum định nghĩa các accountabilities như Product Owner, Scrum Master, Developers; các events như Sprint Planning, Daily Scrum, Sprint Review, Sprint Retrospective; và các artifacts như Product Backlog, Sprint Backlog, Increment.

Nói ngắn gọn: Agile là “why” và “mindset”, còn Scrum là một trong các cách cụ thể để thực hành Agile.

### Lỗi cần tránh / cách nói hay hơn

- Không nói Scrum và Agile là một.

- Không gọi Scrum là methodology cứng nhắc; nên gọi là framework.

- Không nhầm Scrum Master với project manager hoặc team manager.

## Câu 6. Trong Scrum có những role/accountability nào? Trách nhiệm của từng role là gì?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Product Owner tối đa hóa value và quản lý Product Backlog.

- Scrum Master giúp team hiểu và vận hành Scrum hiệu quả, remove impediments.

- Developers tạo ra increment hoàn thành theo Definition of Done.

### Câu trả lời mẫu

Trong Scrum hiện đại, thường gọi là accountabilities thay vì role. Scrum Team gồm Product Owner, Scrum Master và Developers.

Product Owner chịu trách nhiệm tối đa hóa giá trị sản phẩm. PO quản lý Product Backlog, sắp xếp priority, làm rõ Product Goal, trao đổi với stakeholder và đảm bảo team hiểu được mục tiêu cũng như giá trị của các backlog item.

Scrum Master chịu trách nhiệm giúp Scrum Team và tổ chức hiểu, áp dụng Scrum hiệu quả. Scrum Master không phải người ra lệnh cho team, mà là servant leader/coach, hỗ trợ remove impediments, cải thiện collaboration, bảo vệ Scrum events khỏi bị biến thành hình thức và giúp team liên tục cải tiến.

Developers là những người trực tiếp tạo ra increment. Developers không chỉ là coder, mà có thể bao gồm developer, QA, tester, designer, analyst hoặc các thành viên cần thiết để biến backlog item thành sản phẩm hoàn thành. Developers tự quản lý cách làm việc trong Sprint và chịu trách nhiệm về chất lượng increment.

### Lỗi cần tránh / cách nói hay hơn

- Không nói PO là người chỉ viết task cho dev.

- Không nói Scrum Master là sếp của team.

- Không hiểu Developers chỉ là lập trình viên; trong Scrum, Developers là nhóm người tạo increment.

## Câu 7. Product Owner khác Project Manager như thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- PO tập trung product value, backlog, priority, stakeholder needs.

- PM thường tập trung timeline, resource, budget, risk, coordination.

- Trong nhiều công ty, trách nhiệm có thể bị chồng lấn nhưng bản chất khác nhau.

### Câu trả lời mẫu

Product Owner và Project Manager có thể cùng làm việc với stakeholder, nhưng trọng tâm khác nhau. Product Owner tập trung vào giá trị sản phẩm: sản phẩm nên giải quyết vấn đề gì, ưu tiên feature nào trước, backlog item nào tạo value cao nhất, acceptance criteria là gì và Product Goal là gì.

Project Manager thường tập trung vào quản lý dự án: timeline, budget, resource, dependency, risk, reporting và coordination giữa nhiều bên. PM quan tâm nhiều đến việc dự án có đi đúng kế hoạch, đúng ngân sách và đúng phạm vi cam kết hay không.

Trong Scrum chuẩn không có role Project Manager bên trong Scrum Team. Tuy nhiên trong thực tế doanh nghiệp, đặc biệt là outsource hoặc tổ chức lớn, PM vẫn có thể tồn tại để quản lý contract, timeline tổng thể hoặc cross-team coordination. Khi đó cần phân định rõ: PO quyết định priority/value của product, còn PM hỗ trợ project governance và coordination.

### Lỗi cần tránh / cách nói hay hơn

- Không nói PO giống hệt PM.

- Không nói PM luôn không cần thiết trong mọi tổ chức.

- Nên nhấn mạnh sự khác biệt giữa product value và project delivery management.

## Câu 8. Scrum Master có phải team lead hoặc manager không?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Scrum Master không phải manager theo nghĩa command-and-control.

- Scrum Master là servant leader/coach/facilitator.

- Một team lead có thể kiêm Scrum Master ở vài công ty nhưng dễ xung đột trách nhiệm.

### Câu trả lời mẫu

Scrum Master không phải team lead hoặc manager theo nghĩa truyền thống. Scrum Master không phải người giao task, ép deadline hoặc đánh giá performance cá nhân của dev. Trách nhiệm chính của Scrum Master là giúp team hiểu Scrum, vận hành Scrum events hiệu quả, tạo transparency, remove impediments và thúc đẩy continuous improvement.

Trong thực tế, một team lead có thể kiêm vai trò Scrum Master ở một số công ty nhỏ, nhưng cần cẩn thận vì dễ tạo cảm giác Daily Scrum là buổi báo cáo cho sếp. Nếu Scrum Master đồng thời là lead, người đó nên tách rõ hai vai: khi làm Scrum Master thì tập trung facilitation, coaching và hỗ trợ team tự quản lý, không dùng quyền lực quản lý để áp đặt.

### Lỗi cần tránh / cách nói hay hơn

- Không nói Scrum Master là người quản lý team.

- Không nói Scrum Master chịu trách nhiệm delivery thay cho Developers.

- Nên dùng các từ như servant leader, facilitator, coach, remove impediments.

## Câu 9. Developer trong Scrum chỉ có coder không?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Developers là tất cả thành viên trực tiếp tạo increment.

- Có thể gồm dev, QA, tester, designer, analyst, DevOps tùy sản phẩm.

- Developers chịu trách nhiệm plan Sprint Backlog, chất lượng và Definition of Done.

### Câu trả lời mẫu

Không. Trong Scrum, Developers không chỉ có nghĩa là coder. Developers là nhóm người có kỹ năng cần thiết để tạo ra một increment hoàn thành trong Sprint. Tùy team, Developers có thể bao gồm frontend developer, backend developer, QA, automation tester, designer, business analyst, DevOps hoặc data engineer.

Điểm quan trọng là Developers chịu trách nhiệm chuyển các Product Backlog Items thành increment đạt Definition of Done. Họ tự tổ chức cách làm việc, estimate effort, chia nhỏ task, phối hợp với nhau, đảm bảo chất lượng kỹ thuật và minh bạch tiến độ trong Sprint.

### Lỗi cần tránh / cách nói hay hơn

- Không hiểu Developers theo nghĩa hẹp là chỉ người viết code.

- Không tách QA ra khỏi trách nhiệm chất lượng của team; chất lượng là trách nhiệm chung.

- Nên nhấn mạnh tính cross-functional của Scrum Team.

# Nhóm 3: Scrum Events / Ceremonies

## Câu 10. Sprint là gì? Một Sprint thường kéo dài bao lâu?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Sprint là time-box chứa tất cả Scrum events.

- Mục tiêu là tạo increment có giá trị theo Sprint Goal.

- Sprint thường 1-4 tuần, phổ biến là 2 tuần.

### Câu trả lời mẫu

Sprint là một time-box trong Scrum, trong đó Scrum Team làm việc để đạt Sprint Goal và tạo ra một increment có giá trị. Sprint không chỉ là khoảng thời gian code, mà là container chứa các event khác như Sprint Planning, Daily Scrum, Sprint Review và Sprint Retrospective.

Một Sprint thường kéo dài từ 1 đến 4 tuần. Trong nhiều team phần mềm, 2 tuần là độ dài phổ biến vì đủ ngắn để nhận feedback thường xuyên nhưng vẫn đủ dài để hoàn thành một số backlog item có ý nghĩa. Sprint càng dài thì rủi ro đi sai hướng càng lớn; Sprint quá ngắn thì overhead planning/review có thể tăng.

Điểm quan trọng là trong Sprint, team nên tập trung vào Sprint Goal. Scope có thể được làm rõ thêm trong quá trình làm, nhưng không nên thay đổi tùy tiện làm phá vỡ Sprint Goal.

### Lỗi cần tránh / cách nói hay hơn

- Không xem Sprint chỉ là deadline nhỏ.

- Không nói Sprint luôn cố định 2 tuần trong mọi team; 2 tuần chỉ là phổ biến.

- Nên nhắc Sprint Goal để thể hiện hiểu đúng Scrum.

## Câu 11. Sprint Planning là gì? Team cần làm gì trong buổi này?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Xác định tại sao Sprint này có giá trị: Sprint Goal.

- Chọn Product Backlog Items phù hợp capacity và priority.

- Làm rõ cách thực hiện: break task, estimate, dependency, risk.

### Câu trả lời mẫu

Sprint Planning là buổi bắt đầu Sprint, nơi Scrum Team thống nhất mục tiêu của Sprint và các backlog item sẽ được thực hiện. Buổi này nên trả lời ba câu hỏi: tại sao Sprint này có giá trị, Sprint này sẽ làm gì, và công việc sẽ được thực hiện như thế nào.

Product Owner thường giải thích priority, business value và acceptance criteria của các Product Backlog Items. Developers đánh giá effort, technical complexity, dependency, risk và capacity của team. Từ đó team chọn ra scope phù hợp và hình thành Sprint Backlog.

Kết quả quan trọng nhất của Sprint Planning không chỉ là một danh sách task, mà là Sprint Goal rõ ràng, Sprint Backlog có tính khả thi và sự alignment giữa PO và Developers về kỳ vọng delivery.

### Lỗi cần tránh / cách nói hay hơn

- Không biến Sprint Planning thành buổi PO giao task một chiều.

- Không nhận quá nhiều scope vượt capacity chỉ để làm hài lòng stakeholder.

- Nếu requirement chưa rõ, cần làm rõ acceptance criteria trước khi đưa vào Sprint.

## Câu 12. Daily Scrum là gì? Có phải buổi báo cáo cho manager không?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Daily Scrum là buổi inspect progress và adapt plan trong 24h tiếp theo.

- Đối tượng chính là Developers.

- Không phải status report cho manager.

### Câu trả lời mẫu

Daily Scrum là một event ngắn, thường time-box 15 phút, để Developers kiểm tra tiến độ so với Sprint Goal, chia sẻ blocker và điều chỉnh kế hoạch làm việc cho ngày tiếp theo. Mục tiêu là tăng transparency và giúp team phối hợp tốt hơn.

Daily Scrum không phải là buổi báo cáo cho manager. Nếu mọi người chỉ lần lượt nói “hôm qua làm gì, hôm nay làm gì” để báo cáo cho Scrum Master hoặc lead, buổi Daily rất dễ trở thành hình thức. Cách đúng là team tự nhìn vào Sprint Goal, Sprint Backlog, blocker và dependency để điều chỉnh kế hoạch.

Các vấn đề chi tiết như tranh luận technical solution, debug bug phức tạp hoặc phân tích requirement sâu nên được tách ra sau Daily với những người liên quan, tránh làm Daily kéo dài.

### Lỗi cần tránh / cách nói hay hơn

- Không gọi Daily là meeting báo cáo cho sếp.

- Không để Daily biến thành buổi giải quyết mọi vấn đề chi tiết.

- Không bắt buộc chỉ có format 3 câu hỏi cứng; format nào cũng được miễn đạt mục đích inspect/adapt.

## Câu 13. Sprint Review khác Sprint Retrospective như thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Sprint Review tập trung vào product/increment/stakeholder feedback.

- Sprint Retrospective tập trung vào process/team collaboration/improvement.

- Review nhìn ra ngoài sản phẩm; Retro nhìn vào cách team làm việc.

### Câu trả lời mẫu

Sprint Review và Sprint Retrospective đều diễn ra gần cuối Sprint nhưng mục đích khác nhau. Sprint Review tập trung vào sản phẩm. Team demo increment đã hoàn thành, nhận feedback từ stakeholder, thảo luận điều gì đã đạt, điều gì thay đổi trong thị trường hoặc requirement, và Product Backlog có cần điều chỉnh không.

Sprint Retrospective tập trung vào cách team làm việc. Team nhìn lại Sprint vừa rồi để xem điều gì tốt, điều gì chưa tốt, vấn đề nào lặp lại, collaboration có hiệu quả không, estimation có chính xác không, CI/CD hoặc testing có blocker gì không. Từ đó team chọn ra một vài action item cụ thể để cải thiện Sprint sau.

Nói ngắn gọn: Review là inspect/adapt product; Retrospective là inspect/adapt process và teamwork.

### Lỗi cần tránh / cách nói hay hơn

- Không dùng Review để blame cá nhân vì chưa xong task.

- Không biến Retrospective thành nơi than phiền nhưng không có action item.

- Không bỏ qua stakeholder feedback trong Review.

## Câu 14. Nếu Daily Scrum kéo dài quá lâu thì xử lý thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Giữ time-box khoảng 15 phút.

- Tập trung vào Sprint Goal, blocker và plan trong 24h tới.

- Tách thảo luận chi tiết ra sau Daily với người liên quan.

### Câu trả lời mẫu

Nếu Daily Scrum thường xuyên kéo dài, tôi sẽ nhìn lại mục đích của Daily. Daily không phải nơi giải quyết tất cả vấn đề, mà là nơi team đồng bộ nhanh để inspect progress và adapt plan. Vì vậy cần giữ time-box, thường là 15 phút.

Cách xử lý là tập trung câu chuyện vào Sprint Goal, các backlog item đang bị ảnh hưởng, blocker và kế hoạch trong 24 giờ tiếp theo. Những vấn đề kỹ thuật chi tiết, tranh luận solution hoặc phân tích bug phức tạp nên được ghi nhận và tách ra thành discussion sau Daily với đúng người cần tham gia.

Nếu Daily vẫn dài, có thể vấn đề nằm ở backlog chưa rõ, task quá lớn, dependency quá nhiều hoặc team thiếu transparency trên board. Khi đó cần cải thiện cách chia task, cập nhật board và làm rõ blocker sớm hơn.

### Lỗi cần tránh / cách nói hay hơn

- Không chỉ nói “cắt bớt thời gian họp” mà không giải quyết nguyên nhân.

- Không để mọi thành viên phải nghe các discussion không liên quan đến mình.

- Không biến Daily thành buổi technical design dài.

# Nhóm 4: Scrum Artifacts & Backlog

## Câu 15. Product Backlog, Sprint Backlog và Increment là gì?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Product Backlog là danh sách ordered các work cần làm cho product.

- Sprint Backlog là plan của Developers cho Sprint hiện tại.

- Increment là phần sản phẩm hoàn thành, đạt Definition of Done.

### Câu trả lời mẫu

Product Backlog là danh sách được sắp xếp theo thứ tự ưu tiên của những việc cần làm để phát triển sản phẩm. Nó có thể bao gồm feature, bug fix, technical improvement, research item hoặc non-functional requirement. Product Owner chịu trách nhiệm quản lý Product Backlog để tối đa hóa value.

Sprint Backlog là tập hợp các Product Backlog Items được chọn cho Sprint, cộng với kế hoạch của Developers để hoàn thành chúng. Sprint Backlog không chỉ là task list, mà còn thể hiện cách team dự định đạt Sprint Goal.

Increment là phần sản phẩm hoàn thành sau Sprint hoặc trong Sprint, đáp ứng Definition of Done và có thể được kiểm chứng. Một increment tốt nên ở trạng thái usable, nghĩa là có thể demo, test hoặc release nếu business quyết định.

### Lỗi cần tránh / cách nói hay hơn

- Không nhầm Product Backlog với Sprint Backlog.

- Không gọi Increment là code chưa test hoặc feature mới code xong.

- Nên nhắc commitment tương ứng: Product Goal, Sprint Goal và Definition of Done nếu muốn trả lời sâu hơn.

## Câu 16. User Story là gì? Một User Story tốt nên như thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- User Story mô tả nhu cầu từ góc nhìn người dùng hoặc stakeholder.

- Format phổ biến: As a..., I want..., so that...

- Story tốt cần rõ value, nhỏ, testable, có acceptance criteria.

### Câu trả lời mẫu

User Story là cách mô tả một nhu cầu hoặc chức năng từ góc nhìn người dùng hoặc stakeholder. Format phổ biến là: “As a \[type of user\], I want \[goal\], so that \[benefit\]”. Format này giúp team không chỉ biết phải làm gì, mà còn hiểu vì sao việc đó có giá trị.

Một User Story tốt nên đủ nhỏ để hoàn thành trong một Sprint, có business value rõ, có acceptance criteria cụ thể và có thể test được. Ví dụ: “Là người dùng đã đăng nhập, tôi muốn xem danh sách giao dịch theo tháng để kiểm soát chi tiêu cá nhân”. Acceptance criteria có thể bao gồm: hiển thị đúng giao dịch trong tháng được chọn, hỗ trợ phân trang, hiển thị empty state khi không có dữ liệu, và chỉ người sở hữu account mới xem được.

User Story không phải là tài liệu requirement đầy đủ 100%, mà là điểm bắt đầu cho conversation giữa PO, Developers và stakeholder. Vì vậy story cần đủ rõ để team estimate và implement, nhưng vẫn có thể được làm rõ thêm qua trao đổi.

### Lỗi cần tránh / cách nói hay hơn

- Không viết story chỉ dưới dạng task kỹ thuật như “create API get transactions” nếu thiếu value người dùng.

- Không đưa story quá lớn khiến không thể hoàn thành trong Sprint.

- Không bỏ qua acceptance criteria vì sẽ gây hiểu sai giữa dev, QA và PO.

## Câu 17. Definition of Done là gì? Vì sao quan trọng?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- DoD là tiêu chuẩn chung để một item/increment được coi là hoàn thành.

- Có thể gồm code review, test, pass CI, security, docs, deployable.

- Giúp tránh “done giả” và tăng transparency về chất lượng.

### Câu trả lời mẫu

Definition of Done, viết tắt là DoD, là bộ tiêu chuẩn chung mà team dùng để xác định một backlog item hoặc increment đã thật sự hoàn thành hay chưa. Ví dụ một item chỉ được coi là Done khi code đã hoàn thành, đã review, test pass, không còn critical bug, đáp ứng acceptance criteria, cập nhật tài liệu nếu cần và có thể deploy được.

DoD quan trọng vì nó tạo ra sự minh bạch về chất lượng. Nếu không có DoD, mỗi người có thể hiểu “done” khác nhau: dev có thể nghĩ done là code xong, QA nghĩ done là test pass, PO nghĩ done là có thể release. Điều này tạo ra done giả và technical debt.

Trong backend project, DoD có thể bao gồm unit test cho business logic, integration test cho API quan trọng, migration script an toàn, logging phù hợp, error handling, API documentation, review security cơ bản và CI pipeline pass.

### Lỗi cần tránh / cách nói hay hơn

- Không nói Done chỉ là “code xong”.

- Không nhầm Definition of Done với Acceptance Criteria. Acceptance Criteria là điều kiện riêng của từng story; DoD là tiêu chuẩn chung cho mọi item/increment.

- Không đặt DoD quá hình thức nhưng team không thể thực hiện thực tế.

## Câu 18. Story Point là gì? Nó khác estimate theo giờ như thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Story Point là estimate tương đối về effort, complexity, risk, uncertainty.

- Không phải số giờ tuyệt đối.

- Dùng để forecast capacity/velocity, không phải đo performance cá nhân.

### Câu trả lời mẫu

Story Point là đơn vị estimate tương đối dùng để đánh giá độ lớn của một backlog item. Nó không chỉ đo thời gian, mà còn bao gồm effort, complexity, risk và uncertainty. Ví dụ một story có logic đơn giản nhưng dependency nhiều hoặc requirement chưa rõ có thể có point cao hơn.

Story Point khác estimate theo giờ ở chỗ giờ là đơn vị thời gian tuyệt đối, còn point là so sánh tương đối giữa các item. Team có thể nói story A là 2 point, story B phức tạp hơn khoảng gấp đôi nên là 5 point. Sau một vài Sprint, team có thể nhìn velocity trung bình để forecast tương đối số lượng work có thể hoàn thành.

Ưu điểm của Story Point là giúp team tránh tranh luận quá chi tiết về số giờ chính xác trong môi trường nhiều uncertainty. Tuy nhiên point chỉ hữu ích khi team dùng nhất quán và không bị dùng để ép năng suất cá nhân.

### Lỗi cần tránh / cách nói hay hơn

- Không quy đổi cứng 1 point = 1 ngày hoặc 1 point = 8 giờ.

- Không dùng story point để so sánh dev này giỏi hơn dev kia.

- Không estimate story chưa rõ acceptance criteria hoặc còn quá nhiều unknown.

## Câu 19. Velocity là gì? Có nên dùng velocity để ép team tăng năng suất không?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Velocity là lượng work team hoàn thành trong Sprint, thường tính bằng story points.

- Dùng để forecast, planning và hiểu capacity tương đối.

- Không nên dùng làm KPI ép team vì dễ làm méo estimate và giảm chất lượng.

### Câu trả lời mẫu

Velocity là số lượng work mà team hoàn thành trong một Sprint, thường được tính bằng tổng story point của các item đạt Definition of Done. Ví dụ team hoàn thành 28, 30, 26 point trong ba Sprint gần nhất thì có thể forecast capacity khoảng 28 point cho Sprint tiếp theo, tùy vào ngày nghỉ, thành viên vắng, support work hoặc dependency.

Velocity nên được dùng để hỗ trợ planning và forecast, không nên dùng để ép team tăng năng suất. Nếu management yêu cầu velocity Sprint sau phải cao hơn Sprint trước, team có thể bị incentivize estimate point cao hơn, cắt giảm quality hoặc chỉ chọn việc dễ để làm đẹp số liệu.

Cách dùng đúng là xem velocity như một chỉ báo cho khả năng delivery của team trong bối cảnh hiện tại. Nếu velocity giảm, nên xem nguyên nhân như technical debt, requirement unclear, nhiều bug production, dependency ngoài team hoặc capacity thay đổi, thay vì vội kết luận team làm kém.

### Lỗi cần tránh / cách nói hay hơn

- Không dùng velocity làm KPI cá nhân.

- Không so sánh velocity giữa hai team khác nhau vì cách estimate và context khác nhau.

- Không cố tăng velocity bằng cách inflate story point.

# Nhóm 5: Real Project Scenarios & Senior Mindset

## Câu 20. Nếu khách hàng muốn thêm requirement giữa Sprint thì bạn xử lý thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Không nhận tùy tiện vào Sprint.

- Đánh giá urgency, business value, impact tới Sprint Goal, scope, timeline, quality.

- Trao đổi với PO; nếu critical thì trade-off scope, nếu không thì đưa vào Product Backlog.

### Câu trả lời mẫu

Nếu khách hàng muốn thêm requirement giữa Sprint, tôi sẽ không tự ý nhận ngay vào Sprint chỉ để làm hài lòng khách hàng. Đầu tiên cần hiểu requirement đó là gì, vì sao cần gấp, business impact ra sao và có ảnh hưởng đến Sprint Goal hiện tại không.

Sau đó tôi sẽ trao đổi với Product Owner hoặc người chịu trách nhiệm priority. Nếu requirement thật sự critical, ví dụ liên quan đến production issue, compliance hoặc blocker lớn cho business, team có thể thương lượng trade-off: đưa item mới vào Sprint nhưng bỏ hoặc dời một item khác có priority thấp hơn để giữ capacity và chất lượng. Nếu requirement không critical, nên đưa vào Product Backlog, refine và ưu tiên cho Sprint sau.

Điểm quan trọng là thay đổi phải minh bạch về impact. Team cần nói rõ ảnh hưởng tới timeline, scope, testing và quality thay vì âm thầm nhận thêm việc rồi overtime hoặc làm giảm chất lượng.

### Lỗi cần tránh / cách nói hay hơn

- Không nói “Agile là linh hoạt nên khách hàng yêu cầu gì cũng thêm vào Sprint”.

- Không tự ý đổi scope mà không qua PO/stakeholder alignment.

- Không xử lý bằng overtime như giải pháp mặc định.

## Câu 21. Nếu team không hoàn thành hết Sprint Backlog thì nên làm gì?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Không đổ lỗi cá nhân.

- Item chưa Done quay lại Product Backlog để PO reprioritize.

- Phân tích nguyên nhân trong Retro: estimate sai, scope lớn, blocker, requirement unclear, capacity thay đổi.

### Câu trả lời mẫu

Nếu team không hoàn thành hết Sprint Backlog, trước hết cần minh bạch item nào Done, item nào chưa Done theo Definition of Done. Những item chưa Done không nên được tính là hoàn thành một phần nếu chưa đạt tiêu chuẩn. Chúng nên được đưa lại vào Product Backlog để Product Owner xem xét priority cho Sprint sau.

Sau đó team cần phân tích nguyên nhân, không phải để đổ lỗi mà để cải thiện. Có thể do estimate quá thấp, story quá lớn, acceptance criteria chưa rõ, dependency ngoài team, blocker không được raise sớm, production support phát sinh, hoặc team nhận quá nhiều scope so với capacity.

Trong Retrospective, team nên chọn một vài action item cụ thể. Ví dụ chia nhỏ story hơn, refine backlog kỹ hơn, limit work in progress, raise blocker sớm, dành capacity cho bug/support hoặc cải thiện test automation. Mục tiêu là tăng khả năng dự đoán và chất lượng Sprint sau.

### Lỗi cần tránh / cách nói hay hơn

- Không tự động carry over mọi item mà không reprioritize.

- Không tính item chưa đạt DoD là done.

- Không chỉ nói “Sprint sau cố gắng hơn” mà không có cải tiến cụ thể.

## Câu 22. Nếu bạn thấy Scrum trong team chỉ làm hình thức, Daily vẫn họp nhưng không giải quyết vấn đề, bạn sẽ cải thiện thế nào?

| **Mục**                   | **Nội dung**                                                                                                       |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Interviewer muốn nghe** | Bạn hiểu đúng khái niệm, phân biệt được với các khái niệm gần giống, và biết liên hệ với tình huống dự án thực tế. |

### Ý cần nắm

- Quay lại mục đích của Scrum events: transparency, inspect, adapt.

- Làm rõ Sprint Goal, blocker, ownership và action item.

- Dùng Retro để cải thiện process bằng thay đổi nhỏ, đo được.

### Câu trả lời mẫu

Nếu Scrum trong team chỉ làm hình thức, tôi sẽ không bắt đầu bằng việc thêm nhiều meeting hơn. Tôi sẽ nhìn lại từng event có đang phục vụ đúng mục đích không. Daily có giúp team phát hiện blocker và điều chỉnh plan không? Sprint Planning có tạo Sprint Goal rõ không? Review có nhận feedback thật từ stakeholder không? Retrospective có action item cụ thể không?

Với Daily, tôi sẽ đề xuất tập trung vào Sprint Goal và blocker thay vì báo cáo cá nhân. Board cần phản ánh thực tế công việc, ai bị blocked phải được nhìn thấy sớm, và các discussion chi tiết được tách ra sau Daily. Với Retrospective, team nên chọn ít action item nhưng có owner và follow-up ở Sprint sau.

Nếu vấn đề là requirement liên tục không rõ, cần cải thiện backlog refinement và acceptance criteria. Nếu vấn đề là team thiếu ownership, cần làm rõ trách nhiệm, Definition of Done và cách phối hợp dev-QA-PO. Nếu vấn đề là stakeholder không tham gia Review, cần kéo họ vào feedback loop để Scrum không chỉ còn là ceremony nội bộ.

Tôi sẽ tiếp cận bằng các cải tiến nhỏ, có thể đo được, thay vì phê phán team làm sai Scrum. Mục tiêu cuối cùng là giúp Scrum tạo ra transparency, alignment và improvement thật.

### Lỗi cần tránh / cách nói hay hơn

- Không trả lời chung chung là “cần làm đúng Scrum hơn”.

- Không đổ lỗi cho Scrum Master hoặc PO ngay lập tức.

- Nên đưa ví dụ cải tiến cụ thể: rõ Sprint Goal, visible blockers, action items trong Retro, better refinement.

# Cheat Sheet: Các keyword nên dùng khi trả lời

| **Mục**                | **Nội dung**                                                                                           |
|------------------------|--------------------------------------------------------------------------------------------------------|
| **Agile**              | Mindset, iterative, incremental, feedback loop, adaptability, working software, customer collaboration |
| **Waterfall**          | Sequential phases, upfront requirement, predictable plan, costly late change                           |
| **Scrum**              | Framework, Sprint, Scrum Team, events, artifacts, commitments, inspect and adapt                       |
| **Sprint Goal**        | Mục tiêu chung của Sprint, giúp team không chỉ chạy theo task rời rạc                                  |
| **Product Backlog**    | Ordered list of work, managed by Product Owner, aligned with Product Goal                              |
| **Sprint Backlog**     | Selected PBIs plus plan created by Developers to achieve Sprint Goal                                   |
| **Increment**          | Usable piece of product that meets Definition of Done                                                  |
| **Definition of Done** | Shared quality standard, prevents fake done                                                            |
| **Velocity**           | Forecasting signal, not KPI for pressuring team                                                        |
| **Scope change**       | Evaluate impact, discuss with PO, trade-off scope or move to backlog                                   |

# Các hiểu nhầm phổ biến cần tránh

- Agile không có nghĩa là không cần plan. Agile cần plan nhưng plan có thể được điều chỉnh khi có thông tin mới.

- Agile không có nghĩa là không cần documentation. Agile cần tài liệu đủ dùng, đúng mục đích và dễ cập nhật.

- Scrum không phải là Agile. Scrum là một framework để thực hành Agile.

- Daily Scrum không phải buổi báo cáo cho manager.

- Scrum Master không phải sếp của Developers.

- Velocity không nên dùng để ép team tăng năng suất.

- Story Point không nên quy đổi cứng sang giờ.

- Done không phải là code xong; Done phải đạt Definition of Done.

- Requirement thay đổi giữa Sprint không nên nhận tùy tiện; cần đánh giá impact và thống nhất trade-off.

- Retrospective không nên chỉ là buổi than phiền; phải có action item cụ thể.

# Lộ trình ôn 3 ngày

| **Mục**    | **Nội dung**                                                                                                                                   |
|------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| **Ngày 1** | Ôn nhóm 1–2: Agile Foundation và Scrum Basic. Tập nói mỗi câu trong 60–90 giây.                                                                |
| **Ngày 2** | Ôn nhóm 3–4: Scrum Events, Artifacts, Backlog, Story Point, Velocity. Tập đưa ví dụ từ dự án backend/fullstack.                                |
| **Ngày 3** | Ôn nhóm 5: Scenario. Tập trả lời theo cấu trúc: hiểu vấn đề → đánh giá impact → trao đổi với PO/stakeholder → action cụ thể → cải tiến sau đó. |
