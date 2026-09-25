# AI Worklog

## 2026-09-25 — Dựng nền tảng Ngày 1

### Công cụ và prompt

- **AI coding agent:** OpenCode, model gpt-6-luna.
- **Công cụ phát triển khác:** Flutter CLI tạo khung Android/Web; Dart/Flutter dùng để format, analyze, test và build.
- **Prompt chính:** `docs/PROMPT_01.md` — khởi tạo nền tảng Ngày 1, hai tab tiếng Việt, chưa tích hợp AI/camera/lưu trữ, cập nhật README và kiểm tra kết quả.

### AI hỗ trợ như thế nào

- Rà soát hướng dẫn và roadmap, xác nhận repo ban đầu chỉ có tài liệu và Flutter/Android tooling có sẵn.
- Hỗ trợ dựng giao diện Flutter cho hai tab, tên ứng dụng, test điều hướng, README và tài liệu cấu hình dự án.
- Rà soát những gì cần đưa vào GitHub, giữ lịch sử remote ban đầu và kiểm tra để không đưa build artifacts hoặc đường dẫn SDK cục bộ lên repo.

### Kết quả chưa chính xác và cách sửa

- Khi bổ sung kiểm thử viewport hẹp, test dùng `Size(320, 568)` nhưng thiếu import `dart:ui`; `flutter analyze` và `flutter test` báo không nhận diện `Size`. Đã thêm import, chạy lại format/analyze/test và cả ba đều thành công.
- Scaffold Android ban đầu có rule ignore Gradle wrapper. Nếu giữ nguyên khi commit, repo clone có thể thiếu wrapper cần cho build Android. Đã kiểm tra trạng thái Git, thêm rule cho phép commit `gradlew`, `gradlew.bat` và `gradle-wrapper.jar`, đồng thời tiếp tục loại `android/local.properties` khỏi Git.
- **AI trong sản phẩm:** chưa tích hợp model/API, nên chưa có kết quả phân tích sự cố nào để đánh giá là đúng hoặc sai. Chưa tạo ví dụ AI giả; cần ghi lại các kết quả thực tế và cách kiểm chứng sau khi tích hợp.

### Kiểm chứng đã chạy

- `dart format lib test` — hoàn tất.
- `flutter analyze` — không có vấn đề.
- `flutter test` — đạt; test chuyển tab trên viewport 320×568 không phát hiện lỗi render.
- `flutter build web --release` — build thành công.
- `flutter build apk --debug` — build thành công; lúc kiểm tra coding agent chưa có Android device để cài/chạy.
- **Bổ sung xác nhận của chủ dự án:** APK Ngày 1 đã được mở qua Android Studio và chạy trên điện thoại Android thật; hai ảnh đính kèm cho thấy hai tab. Coding agent không thể tự kiểm chứng thiết bị trong phiên do `flutter devices` không thấy Android device.

### Nếu có thêm 7 ngày

1. **Ngày 1–2:** Làm nhập mô tả, chọn/chụp ảnh, xem trước ảnh, kiểm tra nội dung rỗng/kích thước và xử lý quyền bị từ chối.
2. **Ngày 3:** Chọn dịch vụ AI và cách gọi an toàn qua backend/proxy; viết prompt có quy tắc không suy đoán và chốt schema báo cáo.
3. **Ngày 4:** Parse/validate phản hồi; xử lý JSON lỗi, trường thiếu, timeout, lỗi mạng; đánh dấu dữ liệu cần người dùng xác nhận.
4. **Ngày 5:** Làm màn hình sửa/xác nhận, lưu cục bộ và đọc lại lịch sử; không coi bản nháp AI là báo cáo đã xác nhận.
5. **Ngày 6:** Kiểm thử các tình huống rõ ràng, mơ hồ/thiếu địa điểm, ảnh không liên quan, mất mạng và dữ liệu sai schema; chạy trên thiết bị Android.
6. **Ngày 7:** Sửa lỗi, build APK, rà soát secret/quyền riêng tư, hoàn thiện README/worklog và chuẩn bị demo trung thực theo tính năng đã chạy.

Voice/GPS chỉ được cân nhắc sau khi luồng tạo → kiểm tra/chỉnh sửa → xác nhận → lưu → xem lịch sử hoạt động ổn định.

## 2026-09-25 — Ngày 2: nhập mô tả và ảnh

### Công cụ và yêu cầu

- **AI coding agent:** OpenCode, model gpt-6-luna.
- **Công cụ:** Flutter CLI; dependency `image_picker` 1.2.3 được thêm bằng `flutter pub add image_picker`.
- **Yêu cầu:** Thực hiện `docs/implement_plan_day2.md`, làm form nhập mô tả/ảnh, validation và preview; chưa tích hợp AI hoặc lưu trữ.

### AI hỗ trợ như thế nào

- Đọc roadmap và plan Ngày 2, triển khai `CreateReportScreen`, picker camera/gallery, preview cục bộ, validation và widget tests.
- Giữ picker dependency ở mức tối thiểu; không thêm `permission_handler`, permission storage rộng, AI service hoặc cơ sở dữ liệu.

### Kết quả chưa chính xác và cách sửa

- Test ban đầu dùng `find.text` cho mô tả xuất hiện ở cả `EditableText` lẫn preview; chuyển sang key riêng. Test CTA ở ngoài viewport được sửa bằng cách cuộn tới nút trước khi tap.
- Thử pre-decode bằng `ui.instantiateImageCodec` khiến widget test không hoàn tất; bỏ pre-decode đó. Thay vào đó kiểm tra kích thước/bytes/signature và dùng `Image.errorBuilder` làm fallback để không crash khi Flutter không render được ảnh; nhánh decoder-error chưa kiểm chứng trên thiết bị.
- APK build đầu tiên lỗi Kotlin incremental cache do source plugin ở ổ `C:` còn project ở ổ `D:`. Tham số `--android-project-arg=kotlin.incremental=false` xác nhận workaround; sau đó đặt `kotlin.incremental=false` trong `android/gradle.properties` để Android Studio/Flutter dùng chung fix. Build chuẩn thành công; tradeoff là Kotlin có thể biên dịch lâu hơn.
- AI chưa được tích hợp; chưa có đầu ra AI trong sản phẩm để đánh giá.

### Kiểm chứng Ngày 2

- `dart format lib test` — hoàn tất.
- `flutter analyze` — không có vấn đề.
- `flutter test --reporter expanded` — 8 tests đạt: điều hướng/màn hình hẹp, validation rỗng, xem lại mô tả/ảnh, camera/gallery source, hủy picker, permission error, ảnh quá lớn và ảnh không hợp lệ.
- `flutter build web --release` — thành công; có cảnh báo không blocking về Cupertino icon font và Wasm dry-run.
- `flutter build apk --debug` — sau khi đặt `kotlin.incremental=false` trong project config, build thành công. Gradle có cảnh báo non-blocking về restricted Java API.
- `flutter devices` ở agent chỉ thấy Windows, Chrome và Edge. Chủ dự án gửi hai ảnh từ điện thoại Android thật: một ảnh cuộn của form có mô tả và ảnh đã chọn; ảnh kia là system photo picker. Chủ dự án báo ảnh nguồn lớn hơn 10 MiB; ảnh chụp không cho biết dung lượng file sau resize/compress. Điều này xác nhận gallery selection/preview theo báo cáo chủ dự án, không xác nhận camera hoặc từ chối quyền.
