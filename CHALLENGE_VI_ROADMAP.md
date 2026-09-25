# AI Field Assistant — Đề bài tiếng Việt và roadmap thực hiện

> Tài liệu này gồm hai phần: bản diễn giải đầy đủ đề bài cuộc thi bằng tiếng Việt và kế hoạch thực hiện sản phẩm trong 7 ngày. Hạn nộp hiển thị trên đề bài: **23:59 ngày 01/10/2026**. Hãy đối chiếu lại đồng hồ đếm ngược trên trang cuộc thi để chốt lịch cá nhân.

---

# Phần I — Đề bài cuộc thi bằng tiếng Việt

## Thử thách AI Builder 7 ngày dành cho nhà phát triển ứng dụng di động

**Trạng thái:** Đang nhận bài dự thi  
**Thời lượng:** 7 ngày  
**Hình thức:** Cá nhân  
**Thời gian còn lại trên trang lúc đề bài được ghi nhận:** 6 ngày 10 giờ  
**Hạn nộp:** 23:59 ngày 01/10/2026

## 1. Quy định chung

- Được phép và khuyến khích sử dụng các công cụ AI như ChatGPT, Claude, Gemini, Cursor, Copilot, Lovable, v.v.
- Mục tiêu là đánh giá khả năng dùng AI để hiểu và giải quyết một vấn đề thực tế, không phải đánh giá bạn tự viết được bao nhiêu mã hay nhớ được bao nhiêu cú pháp.
- Có thể dùng AI, tài nguyên mã nguồn mở và template. Tuy nhiên, bạn phải hiểu sản phẩm và giải thích được cách nó hoạt động. Không nộp sản phẩm sao chép hoặc tính năng giả, không hoạt động thật.
- Một nguyên mẫu nhỏ, hoạt động được và có tư duy rõ ràng được đánh giá cao hơn một dự án lớn mà bạn không hiểu.

## 2. Thử thách: Xây dựng AI Field Assistant

### Bối cảnh

Nhân viên làm việc tại hiện trường thường không muốn mất nhiều thời gian điền các biểu mẫu dài ngay trong lúc làm việc. Họ nên có thể:

> Chụp ảnh → Nói mô tả → Để AI tạo báo cáo.

Mục tiêu là làm cho việc lập báo cáo nhanh hơn và thuận tiện hơn trong tình huống thực tế.

### Yêu cầu sản phẩm

Xây dựng ứng dụng di động **AI Field Assistant**, cho phép nhân viên hiện trường ghi nhận thông tin bằng ảnh, văn bản hoặc giọng nói, rồi dùng AI chuyển thông tin đó thành báo cáo có cấu trúc.

### Ví dụ

Nhân viên chụp ảnh một thiết bị bị hỏng và nói:

> “Máy điều hòa ở khu vực lễ tân không hoạt động, khách đang phàn nàn vì phòng rất nóng.”

AI có thể chuyển nội dung thành báo cáo như sau:

- **Danh mục (Category):** Hỏng hóc thiết bị (Equipment failure)
- **Địa điểm (Location):** Khu vực lễ tân (Reception)
- **Mức độ ưu tiên (Priority):** Cao (High)
- **Sự cố (Issue):** Máy điều hòa không hoạt động
- **Hành động đề xuất (Suggested action):** Cử nhân viên bảo trì đến xử lý
- **Tóm tắt (Summary):** Nội dung tóm tắt sự cố

Người dùng phải có thể **xem lại và chỉnh sửa** kết quả AI tạo ra trước khi lưu báo cáo.

## 3. Yêu cầu tối thiểu

Ứng dụng cần có:

- Chụp ảnh bằng camera hoặc tải ảnh lên.
- Nhập văn bản hoặc dùng giọng nói.
- Phân tích thông tin bằng AI.
- Tạo báo cáo có cấu trúc.
- Cho phép chỉnh sửa báo cáo AI tạo ra.
- Lưu báo cáo.
- Xem lịch sử báo cáo.
- Trạng thái đang xử lý/tải (loading state).
- Trạng thái lỗi (error state).

Ứng dụng cần có trải nghiệm ưu tiên cho điện thoại (mobile-first) và xử lý các tình huống thường gặp như AI phản hồi chậm, dữ liệu đầu vào không hợp lệ hoặc lỗi mạng.

## 4. Công nghệ

Có thể chọn:

- Flutter
- React Native
- Android/iOS native

Hãy chọn công nghệ phù hợp với cách tiếp cận của bạn và giải thích quyết định kỹ thuật trong README.

## 5. Tính năng cộng thêm

Có thể được cộng điểm nếu triển khai thêm:

- Chế độ ngoại tuyến (offline mode).
- Lưu trữ dữ liệu trên thiết bị (local storage).
- Xếp hàng yêu cầu để gửi khi thiết bị có mạng trở lại (request queue).
- Thu thập vị trí GPS.
- Chuyển giọng nói thành văn bản (voice transcription).
- Thông báo đẩy (push notifications).

## 6. Sản phẩm cần nộp

- **Sản phẩm/bản build/đường dẫn demo hoạt động:** APK, bản TestFlight hoặc demo có thể sử dụng.
- **Mã nguồn:** Đường dẫn GitHub nếu có.
- **README:** Trình bày vấn đề, giải pháp, kiến trúc/quy trình, cách dùng AI, phần đã hoàn thành và các giới hạn.
- **Video demo:** Dài tối đa 5 phút.
- **`AI_WORKLOG.md`:** Ghi lại các công cụ AI đã dùng; AI đã hỗ trợ thế nào; kết quả AI nào không chính xác; bạn đã cải thiện chúng ra sao; và bạn sẽ cải thiện điều gì nếu có thêm 7 ngày.

README cũng cần giải thích kiến trúc ứng dụng, quy trình AI, quyết định kỹ thuật và các hạn chế đã biết.

## 7. Tiêu chí đánh giá

Mỗi tiêu chí được chấm theo thang **0–4 điểm**, mỗi tiêu chí có **trọng số 1**.

1. **Chất lượng prompt:** Prompt có bối cảnh, vai trò và yêu cầu đầu ra rõ ràng không?
2. **Chất lượng kết quả:** Sản phẩm cuối có thể dùng ngay cho công việc không?
3. **Tư duy kiểm chứng:** Bạn có kiểm tra, hiệu đính và loại bỏ thông tin sai do AI tạo ra không?
4. **Tính ứng dụng thực tế:** Sản phẩm có gắn với công việc thật và tiết kiệm được bao nhiêu thời gian?
5. **Trình bày và chia sẻ:** Cách mô tả quy trình có giúp người khác làm lại được không?

## 8. Cách tính điểm cuối

- Có từ **4 lượt đánh giá trở lên:** Bỏ điểm cao nhất và thấp nhất, rồi tính trung bình các điểm còn lại.
- Có **3 lượt đánh giá:** Loại điểm nào lệch khỏi trung vị hơn 1,5 điểm, rồi tính trung bình các điểm còn lại.
- Điểm người đánh giá được tính trọng số theo uy tín của họ. Nếu có điểm từ quản lý, điểm đó có trọng số riêng.
- Mỗi lượt đánh giá đúng hạn được **+10 điểm**; đánh giá qua loa có thể làm giảm uy tín.

## 9. Các mốc XP

- **0 điểm:** Chưa đạt.
- **Từ 8 điểm:** 100 XP (x1).
- **Từ 14 điểm:** 150 XP (x1,5).
- **Từ 18 điểm:** 200 XP (x2).

## 10. Thông tin trên biểu mẫu nộp bài

- Bài dự thi được chấm ẩn danh bởi người đánh giá. Hãy xóa tên và logo cá nhân khỏi tệp trước khi nộp.
- Có thể nộp **tệp sản phẩm cuối cùng hoặc đường dẫn sản phẩm** (ví dụ: Canva, Drive, Figma…).
- Phần **Prompts used** (Prompt đã dùng) là bắt buộc: ghi tên công cụ, ví dụ ChatGPT/NotebookLM/Canva, và nội dung prompt.
- Phần **Process description** (Mô tả quy trình) là bắt buộc, tối thiểu **30 ký tự**.
- Có ô khai báo **số giờ ước tính tiết kiệm được nhờ AI**.
- Có thể cho phép bài dự thi xuất hiện trong showcase sau hạn nộp, khi điểm đã được chốt.
- Có thể chọn chia sẻ nhật ký prompt để đồng nghiệp tham khảo.

Thông tin đánh giá hiển thị trên trang: đánh giá đồng cấp ẩn danh, 100 người đánh giá; người đánh giá được chọn ngẫu nhiên trong toàn công ty; thời hạn đánh giá là 168 giờ cho mỗi bài nộp.

---

# Phần II — Roadmap thực hiện sản phẩm

## 1. Định hướng và mục tiêu

### Sản phẩm nên giải quyết một quy trình cụ thể

Chọn một nhóm công việc hiện trường dễ hiểu, ví dụ nhân viên bảo trì tòa nhà. Tập trung vào quy trình:

1. Chụp ảnh hoặc chọn ảnh, nhập mô tả bằng lời/văn bản.
2. AI đề xuất báo cáo có cấu trúc.
3. Người dùng kiểm tra, sửa thông tin và xác nhận.
4. Lưu báo cáo để xem lại trong lịch sử.

Thông điệp sản phẩm có thể là: **“Ghi nhận sự cố trong khoảng một phút, không cần điền biểu mẫu dài.”** Chỉ nêu con số tiết kiệm thời gian nếu bạn đã tự đo thử và có căn cứ.

### Quy tắc phạm vi

Hoàn thành một luồng chính chạy được từ đầu đến cuối trước khi làm tính năng cộng thêm. Bản MVP nên chứng minh được:

> Ảnh + mô tả → AI tạo báo cáo → người dùng sửa/xác nhận → lưu → xem lại trong lịch sử.

## 2. Ưu tiên tính năng

### P0 — Bắt buộc, làm trước

- Màn hình tạo báo cáo gọn, dễ dùng bằng một tay.
- Chụp ảnh hoặc chọn ảnh từ thư viện.
- Nhập mô tả bằng bàn phím.
- Gọi AI thật và yêu cầu kết quả theo cấu trúc cố định.
- Hiển thị trạng thái đang phân tích, thành công và lỗi.
- Cho phép chỉnh sửa các trường báo cáo trước khi lưu.
- Lưu báo cáo vào bộ nhớ cục bộ và có lịch sử.
- Xử lý trường hợp mất mạng, AI lỗi/chậm, nội dung trống và phản hồi AI sai định dạng.
- Có dữ liệu/demo mẫu hoặc hướng dẫn để người đánh giá thử nhanh.

### P1 — Làm nếu P0 đã ổn định

- Nhập giọng nói/chuyển giọng nói thành văn bản.
- Ghi vị trí GPS, nhưng cho phép người dùng bỏ qua hoặc chỉnh sửa.
- Lọc lịch sử theo mức độ ưu tiên hoặc trạng thái.
- Hiển thị ảnh gắn với báo cáo và cho phép xóa/thay ảnh.
- Cải thiện thiết kế, trạng thái rỗng, xác nhận xóa và thông báo dễ hiểu.

### P2 — Chỉ làm nếu còn dư thời gian

- Hàng đợi gửi yêu cầu khi có mạng trở lại.
- Đồng bộ đa thiết bị, tài khoản người dùng.
- Push notification.
- Dashboard, phân quyền nhiều vai trò hoặc quy trình giao việc hoàn chỉnh.

**Không hy sinh độ tin cậy của luồng P0 để thêm tính năng P1/P2.**

## 3. Chuẩn bị trước khi lập trình

### Chốt quyết định trong 1–2 giờ

- **Nền tảng:** Nếu chưa có dự án/công nghệ bắt buộc, Flutter là lựa chọn thực dụng cho một bản demo Android nhanh; nếu bạn đã làm chủ React Native hoặc native thì dùng công nghệ quen thuộc để giảm rủi ro.
- **Đối tượng:** Chọn một nhóm người dùng, chẳng hạn nhân viên bảo trì tòa nhà.
- **Ngôn ngữ giao diện:** Chọn tiếng Việt hoặc tiếng Anh nhất quán. Dữ liệu ví dụ, README và video nên cùng cách gọi các trường.
- **Trường báo cáo:** Chốt trước schema, ví dụ `category`, `location`, `priority`, `issue`, `suggested_action`, `summary`, `created_at`, `photo_path`, `status`.
- **Lưu trữ:** Bắt đầu bằng lưu cục bộ; không cần đăng nhập và đồng bộ cloud để chứng minh giá trị MVP.
- **AI:** Chọn một mô hình/API có thể nhận văn bản và ảnh. Gọi API qua backend/serverless proxy hoặc dịch vụ AI có cơ chế phù hợp cho ứng dụng di động. Không nhúng secret API key vào mã nguồn hoặc APK.
- **Demo:** Ưu tiên có APK cài được trên Android và video ngắn; nếu không thể phân phối APK, chuẩn bị video và hướng dẫn chạy rõ ràng.

### Chuẩn bị đầu vào và công cụ

- Điện thoại Android thật hoặc emulator; kiểm tra camera, quyền truy cập ảnh và mạng.
- Tài khoản/cấu hình dịch vụ AI, giới hạn chi phí và một phương án dự phòng khi API không hoạt động.
- 5–10 tình huống mẫu, gồm sự cố rõ ràng, thiếu địa điểm, mô tả mơ hồ, không có ảnh, ảnh không liên quan và văn bản rỗng.
- Một thư mục lưu ảnh demo không chứa thông tin cá nhân hoặc dữ liệu nhạy cảm.
- GitHub repo, README nháp, danh sách công việc và nơi lưu lại các prompt/đầu ra AI để viết `AI_WORKLOG.md`.
- Tạo sớm các tệp dự kiến: `README.md`, `AI_WORKLOG.md`, `.gitignore`; không đưa key, token hoặc dữ liệu nhạy cảm vào Git.

## 4. Roadmap 7 ngày

> Mốc dưới đây tính theo ngày làm việc của thử thách. Vì thời gian còn lại có thể ngắn hơn trọn 7 ngày, hãy ghép hoặc rút gọn các bước, nhưng luôn giữ lại thời gian kiểm thử, quay demo và nộp bài.

### Ngày 1 — Chốt phạm vi, thiết kế luồng, dựng dự án

**Việc cần làm**

1. Viết mô tả vấn đề và người dùng mục tiêu trong 2–3 câu.
2. Vẽ luồng màn hình: Tạo báo cáo → Xem/chỉnh sửa kết quả → Lịch sử → Chi tiết báo cáo.
3. Chốt schema báo cáo, các giá trị ưu tiên (Thấp/Trung bình/Cao) và trường nào có thể để trống.
4. Tạo project, cấu hình chạy trên thiết bị/emulator, thêm điều hướng và giao diện khung.
5. Tạo Git repo và README nháp; ghi lại quyết định công nghệ.

**Kết quả cuối ngày:** Mở được ứng dụng; luồng màn hình và cấu trúc dữ liệu đã thống nhất.  
**Không làm:** Đăng nhập, backend người dùng, dashboard hoặc thiết kế quá nhiều màn hình.

### Ngày 2 — Nhập dữ liệu và ảnh

**Việc cần làm**

1. Làm màn hình tạo báo cáo với mô tả văn bản, nút chụp/chọn ảnh và xem trước ảnh.
2. Thêm kiểm tra đầu vào: không gửi nội dung rỗng; giới hạn kích thước ảnh và thông báo lỗi có hướng dẫn.
3. Xử lý quyền camera/thư viện, trường hợp từ chối quyền và hủy chọn ảnh.
4. Làm giao diện phù hợp màn hình nhỏ, bàn phím không che nút thao tác.
5. Chạy thử trên ít nhất một thiết bị/emulator thật.

**Kết quả cuối ngày:** Người dùng nhập mô tả, chọn ảnh và xem lại đầu vào trước khi phân tích.

### Ngày 3 — Tích hợp AI và định dạng báo cáo

**Việc cần làm**

1. Viết prompt có vai trò, bối cảnh, quy tắc không suy đoán và schema đầu ra rõ ràng.
2. Gửi mô tả (và ảnh nếu tích hợp được ngay) đến mô hình.
3. Yêu cầu đầu ra JSON đúng schema; kiểm tra và parse kết quả thay vì hiển thị nguyên văn.
4. Thêm timeout, loading state, nút thử lại và thông báo lỗi mạng/API.
5. Nếu AI trả trường thiếu, JSON lỗi hoặc thông tin không chắc chắn, hiển thị giá trị cần xác nhận thay vì tự khẳng định.
6. Lưu lại prompt, kết quả tốt, kết quả sai và cách bạn sửa để điền `AI_WORKLOG.md`.

**Kết quả cuối ngày:** Có thể đưa đầu vào mẫu vào và nhận báo cáo từ AI trong ứng dụng.  
**Điểm kiểm soát:** Nếu AI/API chưa chạy ổn, dành thời gian sửa tích hợp. Chưa thêm voice/GPS.

### Ngày 4 — Chỉnh sửa, lưu cục bộ và lịch sử

**Việc cần làm**

1. Tạo màn hình kết quả có thể chỉnh sửa từng trường.
2. Phân biệt rõ nội dung AI gợi ý và nội dung người dùng đã xác nhận.
3. Lưu báo cáo cùng ảnh hoặc đường dẫn ảnh vào cơ sở dữ liệu cục bộ.
4. Làm lịch sử có trạng thái rỗng, danh sách báo cáo và màn hình chi tiết.
5. Kiểm tra đóng/mở ứng dụng vẫn còn báo cáo đã lưu.
6. Thêm xác nhận trước khi xóa nếu có chức năng xóa.

**Kết quả cuối ngày:** Hoàn chỉnh luồng cốt lõi từ tạo đến lưu và mở lại báo cáo.

### Ngày 5 — Kiểm thử lỗi, hoàn thiện UX và tính năng cộng thêm có chọn lọc

**Việc cần làm**

1. Kiểm tra mạng yếu/mất mạng, API chậm, lỗi API, đầu vào trống, ảnh lớn và kết quả AI thiếu trường.
2. Bảo đảm người dùng không mất nội dung đã nhập khi yêu cầu thất bại; cho phép thử lại.
3. Rà soát quyền riêng tư: không log key, không gửi dữ liệu ngoài mục đích, không để lộ secret trong app/repo.
4. Chỉ khi các bước trên ổn, thêm một tính năng cộng thêm có giá trị rõ ràng: voice-to-text **hoặc** GPS. Không cố làm cả hai nếu thiếu thời gian.
5. Kiểm tra trên điện thoại: vùng bấm, tương phản, cỡ chữ, thao tác một tay và trạng thái loading.

**Kết quả cuối ngày:** Ứng dụng chịu được lỗi thường gặp và người dùng hiểu cách khôi phục.

### Ngày 6 — Đóng gói, viết tài liệu, chuẩn bị demo

**Việc cần làm**

1. Tạo bản build release/APK; cài lại từ đầu trên thiết bị khác nếu có thể.
2. Viết README: vấn đề, người dùng, giải pháp, cách chạy, kiến trúc, luồng AI, quyết định kỹ thuật, phần hoàn thành và hạn chế.
3. Hoàn thiện `AI_WORKLOG.md` bằng trải nghiệm thật, gồm prompt và ví dụ AI trả sai rồi được bạn kiểm chứng/sửa.
4. Chuẩn bị kịch bản video dưới 5 phút: vấn đề → tạo báo cáo → AI phân tích → người dùng sửa → lưu/lịch sử → xử lý một tình huống lỗi → kiến trúc và giới hạn.
5. Quay thử; bảo đảm chữ đọc được, thông báo không lộ dữ liệu cá nhân, không có màn hình chờ dài.

**Kết quả cuối ngày:** Có APK/demo, README, AI worklog và video gần như hoàn chỉnh.

### Ngày 7 — Kiểm tra cuối và nộp sớm

**Việc cần làm**

1. Làm theo đúng kịch bản demo trên bản build cuối cùng.
2. Kiểm tra sạch secret/API key khỏi GitHub, file cấu hình công khai, ảnh chụp màn hình và video.
3. Mở thử link tải/demo trong cửa sổ riêng tư hoặc trên thiết bị khác; xác nhận quyền truy cập.
4. Kiểm tra repo, README, `AI_WORKLOG.md`, video và bản build đều khớp nhau.
5. Điền biểu mẫu: sản phẩm hoặc link, ít nhất một prompt, mô tả quy trình trên 30 ký tự, số giờ ước tính tiết kiệm và tùy chọn chia sẻ.
6. Xóa tên/logo cá nhân khỏi tệp cần chấm ẩn danh.
7. Nộp trước hạn, không đợi đến phút cuối; giữ lại bằng chứng/link xác nhận nộp.

**Kết quả cuối ngày:** Bài nộp mở được, chạy được, đầy đủ tài liệu và đúng yêu cầu.

## 5. Kiến trúc MVP gợi ý

Giữ kiến trúc nhỏ, dễ giải thích:

```text
Giao diện mobile
  ├─ Nhập mô tả / chọn ảnh
  ├─ Trạng thái phân tích / lỗi / thử lại
  ├─ Màn hình kiểm tra và chỉnh sửa
  └─ Lịch sử / chi tiết
       │
       ├─ AI service → API/backend bảo vệ thông tin xác thực → mô hình AI
       └─ Report repository → lưu cục bộ → lịch sử
```

- **UI:** Các màn hình và trạng thái tương tác.
- **AI service:** Đóng gói yêu cầu, prompt, timeout, parse/validate schema và xử lý lỗi.
- **Report repository:** Tạo, đọc, cập nhật và xóa báo cáo cục bộ.
- **Report model:** Một cấu trúc dữ liệu dùng chung để hiển thị, sửa và lưu.
- **Luồng kiểm chứng:** AI chỉ đề xuất; người dùng sửa/xác nhận trước khi lưu chính thức.

Không cần dựng backend lớn. Tuy nhiên, không nhúng API secret trực tiếp vào ứng dụng phân phối. Nếu thời gian không đủ để dựng backend, dùng dịch vụ/tích hợp được thiết kế cho ứng dụng khách hoặc giới hạn demo an toàn; mô tả trung thực cách xác thực và giới hạn trong README.

## 6. Prompt AI mẫu để bắt đầu

Hãy chỉnh prompt theo mô hình thực tế và kiểm tra bằng nhiều tình huống. Không coi prompt dưới đây là bảo đảm rằng AI luôn đúng.

```text
Bạn là trợ lý lập báo cáo sự cố cho nhân viên bảo trì tòa nhà.
Phân tích mô tả và ảnh được cung cấp để tạo một bản nháp báo cáo ngắn.

Quy tắc:
- Chỉ dùng thông tin có trong mô tả hoặc nhìn thấy rõ trong ảnh.
- Không tự bịa địa điểm, nguyên nhân, mức độ hư hỏng hoặc hành động đã thực hiện.
- Nếu thiếu dữ liệu, dùng chuỗi rỗng hoặc ghi rõ cần người dùng xác nhận.
- priority chỉ được là "low", "medium" hoặc "high".
- suggested_action là đề xuất, không khẳng định công việc đã hoàn tất.
- Trả về JSON hợp lệ đúng cấu trúc bên dưới, không thêm markdown hay lời dẫn.

{
  "category": "",
  "location": "",
  "priority": "medium",
  "issue": "",
  "suggested_action": "",
  "summary": "",
  "needs_confirmation": []
}
```

Khi kiểm chứng, hãy thử các đầu vào mơ hồ và xem AI có bịa địa điểm/nguyên nhân hay không. Cho người dùng sửa mọi trường; không để AI tự quyết định hành động nguy hiểm hoặc thay thế quy trình chuyên môn tại hiện trường.

## 7. Những điều nên ưu tiên

1. **Luồng đầu-cuối hoạt động:** Tạo → AI → sửa → lưu → xem lại.
2. **Độ tin cậy:** Loading, timeout, lỗi rõ ràng, thử lại và giữ lại bản nháp.
3. **Người dùng kiểm soát:** AI tạo bản nháp; người dùng xem và xác nhận.
4. **Tính thực tế:** Tập trung vào một nhóm công việc và một quy trình thực sự mất thời gian.
5. **Bằng chứng kiểm chứng AI:** Chuẩn bị ví dụ AI sai/thiếu và cho thấy bạn phát hiện, sửa ra sao.
6. **Demo dễ đánh giá:** Có dữ liệu mẫu, kịch bản ngắn, chữ dễ đọc, không phụ thuộc mạng hoàn hảo.
7. **Tài liệu trung thực:** Nêu rõ tính năng nào chạy thật, tính năng nào chưa làm và các giới hạn.
8. **Nộp sớm:** Dành ngày cuối cho kiểm tra và lỗi phát sinh, không dành cho tính năng mới.

## 8. Những điều nên tránh

- Không xây quá nhiều tính năng trước khi luồng MVP chạy được.
- Không tạo giao diện chỉ có nút bấm nhưng không có hành vi thật.
- Không tin mù quáng vào nội dung AI; AI có thể suy đoán sai từ ảnh hoặc mô tả.
- Không hiển thị nguyên văn phản hồi AI thay cho kiểm tra schema và xử lý lỗi.
- Không âm thầm biến dữ liệu thiếu thành thông tin khẳng định; đánh dấu cần xác nhận.
- Không nhúng API key/secret vào repo, APK, ảnh chụp màn hình hoặc video.
- Không log nội dung nhạy cảm hay ảnh hiện trường nếu không cần thiết.
- Không dành quá nhiều thời gian cho đăng nhập, đồng bộ cloud, push notification hay kiến trúc phức tạp.
- Không tuyên bố “offline mode” nếu ứng dụng chỉ lưu lịch sử cục bộ nhưng không thể tạo/lưu báo cáo khi mất mạng. Mô tả chính xác hành vi offline đã hỗ trợ.
- Không dùng dữ liệu, số liệu tiết kiệm thời gian hoặc tính năng demo giả như thể đã được kiểm chứng.
- Không quay video quá 5 phút hoặc để phần giới thiệu dài hơn phần demo hoạt động.
- Không để đến sát hạn mới build APK, cấp quyền link hoặc điền biểu mẫu.

## 9. Bộ kiểm thử tối thiểu

Trước khi nộp, thử tối thiểu các trường hợp sau:

| Tình huống | Kết quả mong đợi |
|---|---|
| Mô tả rõ + ảnh phù hợp | AI tạo đủ trường; người dùng sửa và lưu được |
| Chỉ có văn bản, không có ảnh | Vẫn tạo báo cáo được hoặc giải thích rõ nếu không hỗ trợ |
| Mô tả trống | Không gọi AI; báo người dùng cần nhập thông tin |
| Mô tả mơ hồ/thiếu địa điểm | Không bịa; đánh dấu trường cần xác nhận |
| Ảnh không liên quan | AI không khẳng định ảnh chứng minh sự cố; người dùng có thể bỏ/thay ảnh |
| Mất mạng/API lỗi | Thông báo dễ hiểu, giữ nội dung nhập và cho thử lại |
| AI phản hồi chậm | Có loading, timeout và thao tác thử lại |
| AI trả JSON lỗi/thiếu trường | Ứng dụng không crash; báo lỗi hoặc cho sửa/tạo lại |
| Đóng rồi mở lại ứng dụng | Báo cáo đã lưu vẫn hiện trong lịch sử |
| Từ chối quyền camera/ảnh | Hướng dẫn chọn ảnh khác hoặc tiếp tục nếu luồng cho phép |

## 10. Checklist trước khi nộp

### Sản phẩm

- [ ] Cài và mở được bản build/demo.
- [ ] Có chụp ảnh hoặc chọn ảnh.
- [ ] Có nhập văn bản hoặc giọng nói.
- [ ] AI tạo báo cáo theo cấu trúc.
- [ ] Có thể sửa kết quả AI trước khi lưu.
- [ ] Báo cáo lưu được và hiện trong lịch sử sau khi mở lại ứng dụng.
- [ ] Có loading, lỗi, timeout/thử lại và kiểm tra đầu vào.
- [ ] Không có secret/API key trong mã nguồn công khai hoặc bản demo.

### Tài liệu và bài nộp

- [ ] README mô tả vấn đề, giải pháp, kiến trúc, workflow AI, quyết định kỹ thuật và hạn chế.
- [ ] `AI_WORKLOG.md` nêu công cụ, prompt/cách dùng, lỗi AI, cách sửa và việc sẽ cải thiện nếu có thêm 7 ngày.
- [ ] Video demo dài tối đa 5 phút.
- [ ] Có sản phẩm/tệp hoặc link hoạt động và đã kiểm tra quyền truy cập.
- [ ] Biểu mẫu có ít nhất một prompt đã dùng.
- [ ] Mô tả quy trình đạt tối thiểu 30 ký tự.
- [ ] Khai báo số giờ tiết kiệm theo ước tính có căn cứ.
- [ ] Đã xóa tên/logo cá nhân khỏi tệp cần chấm ẩn danh.
- [ ] Đã chọn tùy chọn chia sẻ showcase/nhật ký prompt theo ý muốn.
- [ ] Đã nộp trước deadline và lưu xác nhận nộp.

## 11. Mẫu mô tả quy trình nộp bài

Bạn có thể dùng mẫu dưới đây rồi thay bằng thông tin thật của mình (đảm bảo tối thiểu 30 ký tự):

> Tôi dùng AI để tạo bản nháp báo cáo từ mô tả và ảnh. Sau đó tôi kiểm tra các trường AI suy đoán, chỉnh sửa nội dung, lưu báo cáo và kiểm thử luồng lỗi mạng trước khi đóng gói ứng dụng.

## 12. Mẫu kịch bản video demo dưới 5 phút

1. **0:00–0:30:** Giới thiệu người dùng và vấn đề cần giải quyết.
2. **0:30–1:00:** Mở ứng dụng, chụp/chọn ảnh và nhập mô tả.
3. **1:00–2:00:** Chạy AI; cho thấy loading và báo cáo có cấu trúc.
4. **2:00–2:45:** Chỉ ra một chỗ cần kiểm tra, sửa kết quả và lưu.
5. **2:45–3:30:** Mở lịch sử và xem lại báo cáo.
6. **3:30–4:15:** Minh họa một lỗi thường gặp, ví dụ mất mạng, và cách thử lại/giữ dữ liệu.
7. **4:15–5:00:** Nêu kiến trúc, AI đã hỗ trợ gì, giới hạn hiện tại và hướng cải thiện.

---

## Tóm tắt hành động ngay hôm nay

1. Chọn Flutter/React Native theo công nghệ bạn quen nhất.
2. Chốt một nhóm người dùng và một luồng nghiệp vụ duy nhất.
3. Chốt schema báo cáo và prompt có quy tắc không bịa thông tin.
4. Dựng màn hình nhập liệu, ảnh, kết quả chỉnh sửa và lịch sử.
5. Tích hợp AI thật an toàn; lưu cục bộ; ưu tiên xử lý lỗi.
6. Hoàn thiện README, `AI_WORKLOG.md`, APK/demo và video trước ngày cuối.
7. Nộp sớm sau khi kiểm tra link, quyền truy cập và tính ẩn danh.
