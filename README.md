# AI Field Assistant

Ứng dụng Android-first dành cho nhân viên hiện trường, hướng tới ghi nhận sự cố từ mô tả và ảnh, xem lại báo cáo đề xuất rồi lưu để tra cứu.

## Trạng thái hiện tại — Nền tảng Ngày 1

- Flutter app có hai khu vực điều hướng: **Tạo báo cáo** và **Lịch sử**.
- Màn hình tạo báo cáo giới thiệu quy trình dự kiến; màn hình lịch sử có trạng thái rỗng.
- **Chưa tích hợp** nhập liệu, camera/chọn ảnh, AI, lưu trữ báo cáo hoặc các tính năng voice/GPS.

## Công nghệ và chạy ứng dụng

Dự án dùng Flutter/Dart để xây dựng một ứng dụng cho Android; nền tảng Web được bật để xem trước giao diện khi chưa có thiết bị Android kết nối.

```bash
flutter pub get
flutter run -d <device-id>
```

Liệt kê thiết bị có sẵn bằng `flutter devices`. Để chạy preview trên Chrome, dùng `flutter run -d chrome`. Nếu được yêu cầu, chấp nhận Android SDK licenses bằng `flutter doctor --android-licenses`; sau đó tạo APK debug bằng `flutter build apk --debug`.

## Kiểm tra

```bash
flutter analyze
flutter test
```

Ứng dụng hiện chỉ là khung giao diện ban đầu; chưa có luồng tạo hoặc lưu báo cáo hoạt động.
