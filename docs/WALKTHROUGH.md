# Walkthrough — Ngày 2

Hướng dẫn kiểm tra nhập mô tả và chọn/chụp ảnh. Đầu vào chỉ được xem lại trong phiên hiện tại; app chưa gọi AI hoặc lưu báo cáo.

## 1. Chuẩn bị và khởi chạy

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Nếu Flutter yêu cầu Android SDK licenses, chạy `flutter doctor --android-licenses`. Web preview có thể mở bằng `flutter run -d chrome`; camera và permission cần kiểm tra riêng trên Android.

## 2. Thử nhập đầu vào

1. Ở tab **Tạo báo cáo**, nhập mô tả vào **Mô tả sự cố**.
2. Chọn **Chụp ảnh** để mở camera hoặc **Chọn ảnh** để mở photo picker.
3. Hủy picker: ứng dụng giữ nguyên mô tả và ảnh đã có.
4. Chọn ảnh: xem preview trong form. Chọn ảnh khác để thay ảnh hiện tại.
5. Chạm **Xem lại đầu vào**. Bottom sheet hiển thị mô tả/ảnh và thông báo đầu vào chưa gửi AI, chưa lưu.
6. Thử khi cả mô tả và ảnh đều trống; form phải yêu cầu nhập mô tả hoặc chọn ảnh.
7. Khi quyền bị từ chối hoặc picker lỗi, đọc hướng dẫn trên màn hình; mô tả vẫn được giữ và có thể tiếp tục nhập.

Ảnh tối đa một file, được yêu cầu resize tới 1600×1600 với JPEG quality 85 và bị từ chối nếu file nhận được vượt 10 MiB. Ảnh rỗng, quá lớn hoặc không có signature phổ biến được từ chối và không làm mất ảnh hiện có. Nếu Flutter decoder không render được ảnh dù signature hợp lệ, giao diện hiện fallback; cần kiểm tra nhánh này trên thiết bị.

## 3. Kiểm tra tự động

```bash
dart format lib test
flutter analyze
flutter test
```

Widget tests bao gồm điều hướng, validation đầu vào rỗng, xem lại mô tả/ảnh, camera/gallery source, hủy picker, permission error, ảnh quá lớn/không hợp lệ và viewport 320×568.

## 4. Build APK debug

Project config tắt Kotlin incremental để tránh lỗi cache của Windows khi project và Pub Cache ở hai ổ khác nhau. Build APK bằng lệnh chuẩn:

```bash
flutter build apk --debug
```

APK ở `build/app/outputs/flutter-apk/app-debug.apk`. Đổi lại, các lần build Kotlin có thể lâu hơn.

## Giới hạn kiểm chứng

`flutter build web --release` và APK debug build đã thành công. Chủ dự án cung cấp ảnh cho biết đã thử photo picker và preview trên điện thoại Android thật; ảnh nguồn được báo lớn hơn 10 MiB, còn dung lượng đầu ra không hiện trên ảnh. Camera và từ chối quyền vẫn cần kiểm tra thủ công. Môi trường coding agent không có Android device kết nối để lặp lại phép thử. Đầu vào không được gửi mạng hoặc lưu thành báo cáo; mô tả ở widget state và ảnh là file tạm do picker cung cấp, không đảm bảo còn sau khi app đóng.
