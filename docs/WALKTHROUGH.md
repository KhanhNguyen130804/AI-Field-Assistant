# Walkthrough

Hướng dẫn chạy thử **những gì ứng dụng hiện có**. Đây là prototype giao diện Ngày 1, chưa phải luồng tạo báo cáo hoạt động.

## 1. Chuẩn bị và khởi chạy

Cần cài Flutter; để chạy Android cần thêm Android SDK và một thiết bị/emulator. Kiểm tra thiết bị Flutter nhận diện được:

```bash
flutter pub get
flutter devices
```

Chạy trên Android bằng ID hiển thị trong danh sách:

```bash
flutter run -d <device-id>
```

Nếu chưa có Android device/emulator, chạy bản xem trước trên Chrome:

```bash
flutter run -d chrome
```

Nếu Flutter yêu cầu Android SDK licenses, chạy `flutter doctor --android-licenses` và chấp nhận theo hướng dẫn trên máy.

## 2. Kiểm tra hai khu vực

1. Khi mở ứng dụng, tab **Tạo báo cáo** được chọn. Màn hình giới thiệu mục tiêu và ba bước dự kiến: ghi nhận thông tin, tạo bản nháp, kiểm tra và lưu.
2. Đọc thông báo trên màn hình: nhập liệu, camera, AI và lưu trữ hiện chưa được tích hợp.
3. Chạm tab **Lịch sử**. Màn hình hiển thị trạng thái **Chưa có báo cáo** và giải thích dữ liệu chỉ xuất hiện khi lưu trữ được triển khai.
4. Chạm lại **Tạo báo cáo** để xác nhận điều hướng hoạt động.

## 3. Kiểm tra tự động và build Android

```bash
flutter analyze
flutter test
```

Widget test hiện kiểm tra chuyển tab và không có lỗi render ở viewport 320×568. Tạo APK debug bằng:

```bash
flutter build apk --debug
```

## Giới hạn

Hiện không thể nhập mô tả, chụp/chọn ảnh, gọi AI, sửa báo cáo hay lưu dữ liệu. Tab Lịch sử vì vậy luôn rỗng. Không có yêu cầu mạng hoặc dữ liệu demo giả trong walkthrough này.
