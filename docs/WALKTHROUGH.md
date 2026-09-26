# Walkthrough — Ngày 2 và Ngày 3 (Task 3–4)

Hướng dẫn kiểm tra nhập mô tả/chọn ảnh (Ngày 2), khởi tạo Firebase/App Check (Ngày 3 Task 3) và service Gemini đã viết (Ngày 3 Task 4). Đầu vào chỉ được xem lại trong phiên hiện tại; app chưa gọi AI thật hoặc lưu báo cáo.

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

Widget tests bao gồm điều hướng, validation đầu vào rỗng, xem lại mô tả/ảnh, camera/gallery source, hủy picker, permission error, ảnh quá lớn/không hợp lệ và viewport 320×568. Từ Task 4 Ngày 3, thêm 20 service tests ở `test/gemini_report_service_test.dart` (fake sender, không cần Firebase/network): parse draft, MIME sniffing, chặn đầu vào, timeout/quota/App Check/config/block/server error. Toàn bộ hiện 33/33 đạt.

## 4. Build APK debug

Project config tắt Kotlin incremental để tránh lỗi cache của Windows khi project và Pub Cache ở hai ổ khác nhau. Build APK bằng lệnh chuẩn:

```bash
flutter build apk --debug
```

APK ở `build/app/outputs/flutter-apk/app-debug.apk`. Đổi lại, các lần build Kotlin có thể lâu hơn.

Bản APK debug đã được chủ dự án kiểm thử thủ công trên thiết bị thật theo `docs/MANUAL_TESTCASES_APK.md` (18/20 PASS ngày 26/09/2026). Lưu ý từ kiểm thử thực tế: app không khai báo quyền runtime nào — camera mở qua Intent hệ thống và ảnh qua Photo Picker của Android, nên màn Thông tin ứng dụng hiển thị "không có quyền nào" nhưng camera/ảnh vẫn hoạt động (đúng thiết kế); và photo picker tự resize/nén ảnh (1600px, JPEG q85) nên ảnh gốc > 10 MiB thường về dưới ngưỡng trước khi app kiểm tra.

## 5. Khởi tạo Firebase và App Check debug (Ngày 3 Task 3)

- App hiện khởi tạo Firebase khi mở và ở chế độ debug kích hoạt App Check debug provider (Android/Web).
- Build cần các file cấu hình FlutterFire (`lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`); các file này đã được commit từ Task 3, nhưng nếu dùng project Firebase khác phải chạy lại `flutterfire configure`.
- Lần chạy debug đầu, log (`flutter run` hoặc `adb logcat`) có dòng `Firebase App Check debug token: <token>`. Đăng ký token này trong Firebase Console (App Check → Apps → Manage debug tokens); không commit hay chụp màn hình token.
- Sau khi đăng ký, chạy lại app: log cold start phải có `FirebaseApp initialization successful` và không có error/exception của Firebase/App Check. Đã kiểm chứng như vậy trên điện thoại Android thật ngày 26/09/2026 (agent bắt log qua `adb logcat`, điện thoại kết nối adb không dây).
- Token chỉ được xác nhận backend chấp nhận ở request Gemini đầu tiên (Task 6); Console chưa có metric cho tới khi có request. Web debug provider chưa verify trên Chrome.

## 6. Service Gemini đã có nhưng chưa nối UI (Ngày 3 Task 4)

- `lib/services/gemini_report_service.dart` gửi text/ảnh tới `gemini-3.8-flash` qua Firebase AI Logic với `responseSchema`, parse/validate qua `ReportDraft.fromJson`, timeout 60 giây, chặn đầu vào rỗng/ảnh > 4 MiB/loại lạ và ánh xạ lỗi sang thông báo tiếng Việt.
- Service **chưa được gọi từ màn hình nào** — app không có nút tạo draft AI; walkthrough này chưa có phần thao tác AI trên màn hình. Đó là việc của Task 5, smoke test thật là Task 6.
- Unit test (20 case, fake sender) nằm ở `test/gemini_report_service_test.dart`; chạy bằng `flutter test test/gemini_report_service_test.dart`.

## Giới hạn kiểm chứng

`flutter build web --release` và APK debug build đã thành công (lịch sử Ngày 2; lặp lại sau Task 4). Ngày 3 Task 3: analyze toàn dự án sạch, `flutter test` 13/13 đạt, `flutter build web --release` thành công và khởi tạo Firebase/App Check kiểm chứng trên Android thật qua `adb logcat` (điện thoại chủ dự án kết nối adb không dây). Ngày 3 Task 4 (hai lần trong ngày 26/09/2026): analyze sạch, `flutter test` 33/33 đạt, build web + APK debug thành công; **chưa gọi Gemini thật** — mọi test dùng fixture tổng hợp. Chủ dự án đã kiểm thử APK debug trên thiết bị thật theo `docs/MANUAL_TESTCASES_APK.md`: 18/20 PASS; camera/ảnh hoạt động không cần quyền runtime (Intent + Photo Picker) và ảnh 12 MB sau resize của picker còn dưới 10 MiB nên ngưỡng 10 MiB của form khó kích hoạt. Đầu vào không được gửi mạng hoặc lưu thành báo cáo; mô tả ở widget state và ảnh là file tạm do picker cung cấp, không đảm bảo còn sau khi app đóng. Service AI chưa nối UI, chưa có request Gemini thật, chưa có màn hình draft.
