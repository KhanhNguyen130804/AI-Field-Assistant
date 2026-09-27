# Walkthrough — Ngày 2 và Ngày 3 (Task 3–5)

Hướng dẫn kiểm tra nhập mô tả/chọn ảnh (Ngày 2), khởi tạo Firebase/App Check (Ngày 3 Task 3), service Gemini (Ngày 3 Task 4) và luồng "Phân tích bằng AI" + màn bản nháp AI đã nối thật (Ngày 3 Task 5). Đầu vào được gửi tới Gemini khi người dùng bấm CTA; draft chỉ xem lại, chưa sửa/lưu được.

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

Widget tests bao gồm điều hướng, validation đầu vào rỗng, xem lại mô tả/ảnh, camera/gallery source, hủy picker, permission error, ảnh quá lớn/không hợp lệ và viewport 320×568. Từ Task 4 Ngày 3, service tests ở `test/gemini_report_service_test.dart` (fake sender, không cần Firebase/network): parse draft, MIME sniffing, chặn đầu vào, timeout/quota/App Check/config/block/server error. Từ Task 5 Ngày 3, widget_test.dart thêm 8 test luồng AI và service tests thêm ánh xạ App Check thật + 3 test model fallback. Toàn bộ hiện **45/45 đạt**.

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
- Token được backend chấp nhận đã được xác nhận bằng request Gemini thật đầu tiên (Task 5, 27/09/2026). Lưu ý: cài đè/gỡ cài app có thể đổi debug token → 403 "App attestation failed"; app giờ hiển thị đúng thông báo App Check cho lỗi này — đăng ký lại token trong Console. Web debug provider chưa verify trên Chrome.

## 6. Luồng "Phân tích bằng AI" và màn bản nháp (Ngày 3 Task 5)

1. Ở tab **Tạo báo cáo**, nhập mô tả và/hoặc chọn ảnh, rồi bấm **Phân tích bằng AI**.
2. Trong lúc chờ: thanh tiến trình + dòng "Đang phân tích…"; cả 4 nút (Phân tích/Chụp ảnh/Chọn ảnh/Xem lại) bị khóa; mô tả và ảnh giữ nguyên.
3. Thành công: mở màn **"Bản nháp AI"** với tiêu đề "Bản nháp AI — cần kiểm tra, chưa lưu"; các trường chỉ hiện khi có nội dung; trường AI chưa chắc có badge "Cần xác nhận" và danh sách "Các trường AI chưa đủ căn cứ, cần bạn xem lại"; `suggested_action` kèm dòng "Đây là hành động đề xuất, chưa phải việc đã thực hiện."; phần cuối hiển thị lại mô tả/ảnh gốc. **Màn này chỉ xem — chưa có sửa/lưu/xác nhận** (thuộc Ngày 4).
4. Lỗi (mạng/timeout/quota/App Check/JSON sai): thông báo tiếng Việt ở form, mô tả + ảnh giữ nguyên, bấm lại được.
5. Bấm Back từ draft: về form với input nguyên, có thể phân tích lại.

Model dùng: **chính `gemini-3.8-flash`** (chất lượng cao, free 20 request/ngày/model); khi hết quota tự thử **`gemini-3.5-flash-lite`** (500 request/ngày, chất lượng thấp hơn — draft có thể cần xác nhận nhiều hơn) trong cùng lần bấm. Lỗi không phải quota không kích hoạt fallback. Chi tiết và bằng chứng log ở `docs/SESSION_2026-09-26_TASK5.md` mục 4–6; bộ test case thủ công cho luồng này ở `docs/MANUAL_TESTCASES_TASK5.md`.

Debug build in log chẩn đoán `ReportDraft request failed: <lỗi SDK>` qua `adb logcat` — dùng để xác định nguyên nhân thật khi test thiết bị; không log prompt/ảnh.

## 7. Service Gemini (Ngày 3 Task 4, đã nối UI từ Task 5)

- `lib/services/gemini_report_service.dart` gửi text/ảnh tới Gemini qua Firebase AI Logic với `responseSchema`, parse/validate qua `ReportDraft.fromJson`, timeout 60 giây, chặn đầu vào rỗng/ảnh > 4 MiB/loại lạ và ánh xạ lỗi sang thông báo tiếng Việt. Model chính `gemini-3.8-flash`, fallback `gemini-3.5-flash-lite` khi quota.
- Service đã được nối vào form từ Task 5 (mục 6); request Gemini thật đã chạy đầu-cuối trên thiết bị (27/09/2026).
- Unit test (27 case, fake sender/factory) nằm ở `test/gemini_report_service_test.dart`; chạy bằng `flutter test test/gemini_report_service_test.dart`.

## Giới hạn kiểm chứng

`flutter build web --release` và APK debug build đã thành công (lịch sử Ngày 2; lặp lại sau Task 4 và Task 5). Ngày 3 Task 3: analyze sạch, `flutter test` 13/13, build web thành công, khởi tạo Firebase/App Check kiểm chứng trên Android thật qua `adb logcat`. Ngày 3 Task 4: analyze sạch, `flutter test` 33/33, build web + APK thành công. Ngày 3 Task 5 (26–27/09/2026): analyze sạch, `flutter test` **45/45**, build web + APK thành công; **request Gemini thật đã chạy đầu-cuối trên thiết bị Android** (agent lái qua adb) — draft mở, không bịa trường, fallback quota hoạt động theo log. Chưa chạy đủ 31 test case thủ công trong `docs/MANUAL_TESTCASES_TASK5.md`. Task 5 chưa commit. Mô tả/ảnh không được lưu thành báo cáo; mô tả ở widget state và ảnh là file tạm do picker cung cấp, không đảm bảo còn sau khi app đóng. Màn draft chỉ xem — chưa có chỉnh sửa/lưu.
