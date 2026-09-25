# AI Worklog

## 2026-09-25 — Nền tảng Ngày 1

- **Công cụ:** OpenCode (gpt-6-luna), coding agent.
- **Prompt:** Yêu cầu triển khai riêng nền tảng Ngày 1 cho AI Field Assistant: xác nhận Flutter/Android, tạo app khởi chạy được, hai tab tiếng Việt, không giả lập AI/camera/lưu trữ, và cập nhật README.
- **Sử dụng:** Khởi tạo Flutter Android/Web, tạo giao diện điều hướng và trạng thái rỗng, cập nhật nhãn ứng dụng và tài liệu.
- **Kiểm chứng:** `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build web --release` và `flutter build apk --debug` đều hoàn tất thành công. Widget test kiểm tra chuyển tab trên viewport 320×568 và không phát hiện lỗi render. Lần đầu thêm kiểm tra viewport hẹp, analyze/test báo thiếu import cho `Size`; đã thêm `dart:ui` và chạy lại thành công.
- **Đánh giá AI trong ứng dụng:** Chưa tích hợp AI ở giai đoạn này nên chưa có đầu ra AI để đánh giá.
