# Kế hoạch Ngày 6 — Đóng gói, tài liệu và chuẩn bị demo

> Nhánh: `codex/day6`, bắt đầu từ commit `ec35228` (PDF export). Baseline tại lúc lập kế hoạch: tracked tree sạch; `docs/HOME_DEVICE_TEST_CHECKLIST.md` là thay đổi chưa theo dõi có trước và phải giữ nguyên. Các kết quả PDF `126/126`, analyzer và APK build trong worklog là bằng chứng lịch sử, không phải lần chạy của kế hoạch này.

> **Kết quả thực hiện (30/09/2026):** Host formatter/analyzer/full tests/SQLite FFI đều PASS; APK release build thành công, cài đè và mở được trên AVD Android 35. GitHub branch được tạo/push và remote SHA đã đối chiếu. Chưa thao tác các luồng bên trong app trên Android, chưa quay video; vì vậy Ngày 6 chưa đạt 100%, xem từng gate bên dưới.

## 1. Mục tiêu

Chuẩn bị bản demo có thể tái lập, gắn tài liệu với đúng mã nguồn và ghi rõ mọi giới hạn. Không mở thêm chức năng sản phẩm trong Ngày 6. Chỉ gọi một hạng mục hoàn thành khi có bằng chứng mới đúng mức: mã, test host, APK build, thiết bị, dịch vụ AI và file video là các bằng chứng riêng.

## 2. Hiện trạng và ràng buộc đã biết

- MVP có mã cho nhập mô tả/ảnh, Firebase AI Logic draft, review, SQLite Android, History/detail và PDF cục bộ.
- Request AI gần nhất được ghi trong tài liệu bị App Check chặn. Không phát sinh request thật trong kế hoạch này nếu không có lý do kiểm chứng cụ thể và App Check đã sẵn sàng; chỉ dùng dữ liệu tổng hợp.
- Persistence text-only đã được xác minh trên Android trong một lượt trước. Persistence ảnh và thao tác save/read offline vẫn `BLOCKED`/chưa xác minh.
- PDF có host tests và APK debug build lịch sử, nhưng document picker, mở PDF, Android share sheet và Zalo chưa được thử trên thiết bị.
- `android/app/build.gradle.kts` ký release bằng debug key. Có thể tạo artifact release để đánh giá, nhưng không gọi đó là bản phát hành có chữ ký an toàn.
- Git remote cần xác thực. Không đưa credential/token vào source, lệnh có log, tài liệu hoặc commit.

## 3. Phạm vi và trình tự

### Task 1 — Baseline và nguồn sự thật

1. Xác nhận branch/HEAD/status, Dart/Flutter, thiết bị khả dụng và trạng thái remote; giữ tệp untracked có trước.
2. Đối chiếu Roadmap, README, context, walkthrough, worklog, PDF plan và các phiếu kiểm thử.
3. Không dùng output lịch sử như kết quả mới; không dùng dữ liệu người dùng hoặc gọi Gemini để tạo demo.

**Đầu ra:** baseline Ngày 6 gắn với commit và danh sách blocker hiện hành.

### Task 2 — Kiểm chứng mã nguồn và đóng gói Android

1. Chạy formatter dry-run, `flutter analyze`, toàn bộ `flutter test` và test SQLite FFI liên quan.
2. Tạo APK release từ đúng HEAD nếu SDK/dependency cho phép; ghi lệnh, exit code, SHA-256 và cảnh báo build. Tách rõ “artifact build được” khỏi “release signing/production App Check đã sẵn sàng”.
3. Kiểm tra thiết bị; nếu có thiết bị phù hợp, chỉ cài đè APK mới và dùng dữ liệu tổng hợp. Kiểm tra UI, lưu/đọc, PDF save/share theo khả năng; không gỡ app, clear data, dùng media cá nhân hoặc ngắt Wi-Fi khi ADB Wireless là kênh duy nhất.
4. Nếu không có thiết bị hoặc build bị chặn, đánh dấu từng case `BLOCKED`/`NOT RUN`, nêu đúng nguyên nhân và không dùng APK cũ thay cho build mới.

**Đầu ra:** phiếu kiểm chứng có kết quả theo từng môi trường và APK hash nếu build thành công.

### Task 3 — Tài liệu đúng trạng thái mã

1. Cập nhật README với luồng, cách chạy, dependencies quan trọng, trạng thái PDF, build command, giới hạn Firebase/App Check, signing và bằng chứng thiết bị.
2. Đồng bộ `CONTEXT_SUMMARY.md` và `WALKTHROUGH.md`; phân biệt code/host/device/AI thật. Sửa trạng thái Git cũ “PDF chưa commit” nếu không còn đúng.
3. Thêm entry Ngày 6 vào `AI_WORKLOG.md`: công cụ, tác vụ, lỗi/giới hạn và kết quả vừa kiểm tra. Chỉ ghi ví dụ AI sai nếu worklog/evidence đã có ví dụ thật; không dựng response hồi cứu.
4. Không tiết lộ Firebase client values, token, log thô, dữ liệu/ảnh người dùng hoặc credential.

**Đầu ra:** README, context, walkthrough và worklog thống nhất với source/commit mới.

### Task 4 — Kịch bản demo dưới 5 phút

1. Tạo kịch bản có mốc thời gian: vấn đề → nhập dữ liệu tổng hợp/chọn ảnh → AI (chỉ nếu dịch vụ chấp nhận) → review/sửa → lưu/History → PDF nếu thiết bị hỗ trợ → một tình huống lỗi → kiến trúc và giới hạn.
2. Chuẩn bị đường dự phòng không giả lập: nếu App Check chặn thì dừng ở thông báo lỗi/giữ input và giải thích; không thay AI thật bằng output giả.
3. Quay video chỉ trên thiết bị/desktop thực tế nếu có công cụ phù hợp; xem lại để bảo đảm chữ đọc được và không lộ dữ liệu nhạy cảm. Nếu môi trường không thể quay hoặc thiếu thiết bị, giữ script và đánh dấu video `NOT RUN` thay vì tạo video giả.

**Đầu ra:** script video dưới 5 phút; video chỉ được ghi là hoàn thành khi artifact thực sự tồn tại và đã được xem lại.

### Task 5 — Review, commit và xuất bản

1. Review diff, phạm vi file, docs, test/build evidence, secrets và trạng thái Git.
2. Chỉ stage file thuộc Day 6; tuyệt đối để nguyên `docs/HOME_DEVICE_TEST_CHECKLIST.md`.
3. Chạy `git diff --cached --check`, xem staged diff/stat và xác nhận không còn unstaged thay đổi thuộc task.
4. Commit trên `codex/day6`, push cùng branch; kiểm tra remote SHA bằng local HEAD và porcelain sau push.
5. Nếu GitHub xác thực không sẵn sàng, giữ commit local, không ghi credential vào repo và báo chính xác bước đăng nhập cần thiết.

## 4. Điều kiện nghiệm thu

- **Host:** formatter, analyzer, full tests và APK release đều có kết quả mới gắn với HEAD; hoặc từng mục có blocker rõ ràng.
- **Tài liệu:** README/context/walkthrough/worklog mô tả thống nhất và không ghi lùi bằng chứng.
- **Demo:** script dưới 5 phút có sẵn; video chỉ PASS nếu quay và kiểm tra được. Không giả lập phần AI.
- **Android:** các case đã chạy có bằng chứng; các case ảnh/offline/PDF/AI chưa chạy vẫn được ghi BLOCKED/NOT RUN.
- **GitHub:** branch `codex/day6` được push và remote SHA khớp HEAD. Commit local đơn lẻ không đạt điều kiện này.

“100%” chỉ có nghĩa là mọi điều kiện trên có bằng chứng PASS; phần bị chặn bởi thiết bị, App Check, signing hoặc GitHub credential phải được báo là chưa hoàn tất, không được đổi nhãn để đóng task.

## 5. Kết quả theo gate tại lượt này

- **Task 1 — PASS:** xác nhận source, nhánh local, toolchain và thiết bị; giữ nguyên checklist untracked.
- **Task 2 — PARTIAL:** format 29/29, analyzer sạch, 126/126 full tests, SQLite FFI 10/10, APK release build thành công; cài đè/mở app trên AVD. Chưa thử tính năng bên trong app trên Android hoặc trên điện thoại thật.
- **Task 3 — PASS:** README, context summary, walkthrough và worklog được đồng bộ với kết quả mới; ví dụ AI không chính xác chưa được dựng vì chưa có bằng chứng thực.
- **Task 4 — PARTIAL:** kịch bản 4:40 đã tạo; video chưa quay/xem lại.
- **Task 5 — PASS:** sáu tệp Day 6 đã commit; `git push -u origin codex/day6` thành công và `git ls-remote` khớp local SHA. Untracked checklist có trước không được stage.
